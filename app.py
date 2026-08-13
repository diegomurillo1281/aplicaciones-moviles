from flask_caching import Cache
import sqlite3
from flask import Flask, request, jsonify
from flask_cors import CORS
from flasgger import Swagger
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)

swagger = Swagger(app)

cache = Cache(
    app,
    config={
        "CACHE_TYPE": "simple"
    }
)

# Permite que Flutter Web pueda consumir la API
CORS(app)

DATABASE = "trendvibe.db"


# ==========================
# CONEXIÓN A LA BASE DE DATOS
# ==========================

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_usuario TEXT NOT NULL UNIQUE,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS publicaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        contenido TEXT NOT NULL,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(usuario_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
    )
    """)

    # Índices de optimización
    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_publicaciones_usuario
    ON publicaciones(usuario_id)
    """)

    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_publicaciones_fecha
    ON publicaciones(fecha_creacion)
    """)

    conn.commit()
    conn.close()

init_db()

# ==========================
# RUTA PRINCIPAL
# ==========================

@app.route("/")
def home():
    return jsonify({
        "mensaje": "TrendVibe API funcionando correctamente"
    })


# ==========================
# REGISTRO
# ==========================
@app.route("/api/auth/register", methods=["POST"])
def register():
    """
    Registro de usuario

    ---
    tags:
      - Autenticación

    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            nombre_usuario:
              type: string
            correo:
              type: string
            contrasena:
              type: string

    responses:
      201:
        description: Usuario registrado correctamente
      400:
        description: Error de validación
    """

    data = request.get_json()

    if not data:
        return jsonify({"error": "No se enviaron datos"}), 400

    nombre = data.get("nombre_usuario")
    correo = data.get("correo")
    password = data.get("contrasena")

    if not nombre or not correo or not password:
        return jsonify({"error": "Todos los campos son obligatorios"}), 400

    password_hash = generate_password_hash(password)

    conn = get_db_connection()
    cursor = conn.cursor()

    try:

        cursor.execute("""
        INSERT INTO usuarios(nombre_usuario,correo,contrasena)
        VALUES(?,?,?)
        """, (nombre, correo, password_hash))

        conn.commit()

        return jsonify({
            "mensaje": "Usuario registrado correctamente"
        }), 201

    except sqlite3.IntegrityError:

        return jsonify({
            "error": "El usuario o correo ya existe"
        }), 400

    finally:
        conn.close()


# ==========================
# LOGIN
# ==========================

@app.route("/api/auth/login", methods=["POST"])
def login():
    """
    Inicio de sesión

    ---
    tags:
      - Autenticación

    parameters:
      - in: body
        name: body
        required: true

        schema:
          type: object

          properties:

            correo:
              type: string

            contrasena:
              type: string

    responses:

      200:
        description: Inicio de sesión exitoso

      401:
        description: Credenciales incorrectas
    """
    data = request.get_json()

    if not data:
        return jsonify({"error": "No se enviaron datos"}), 400

    correo = data.get("correo")
    password = data.get("contrasena")

    conn = get_db_connection()

    usuario = conn.execute(
        "SELECT * FROM usuarios WHERE correo=?",
        (correo,)
    ).fetchone()

    conn.close()

    if usuario is None:

        return jsonify({
            "error": "Correo no registrado"
        }), 401

    if check_password_hash(usuario["contrasena"], password):

        return jsonify({

            "mensaje": "Inicio de sesión exitoso",

            "usuario": {

                "id": usuario["id"],
                "nombre_usuario": usuario["nombre_usuario"],
                "correo": usuario["correo"]

            }

        }), 200

    return jsonify({
        "error": "Contraseña incorrecta"
    }), 401


# ==========================
# CREAR PUBLICACIÓN
# ==========================

@app.route("/api/publicaciones", methods=["POST"])
def crear_publicacion():

    data = request.get_json()

    usuario_id = data.get("usuario_id")
    titulo = data.get("titulo")
    contenido = data.get("contenido")

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""

    INSERT INTO publicaciones(usuario_id,titulo,contenido)

    VALUES(?,?,?)

    """, (usuario_id, titulo, contenido))

    conn.commit()

    conn.close()

    cache.clear()

    return jsonify({
        "mensaje": "Publicación creada correctamente"
    }), 201


# ==========================
# LISTAR PUBLICACIONES
# ==========================

@cache.cached(timeout=30)
@app.route("/api/publicaciones", methods=["GET"])
def listar_publicaciones():
    """
    Obtener publicaciones

    ---
    tags:
      - Publicaciones

    parameters:
      - name: page
        in: query
        type: integer

      - name: per_page
        in: query
        type: integer

    responses:
      200:
        description: Lista de publicaciones
    """

    pagina = request.args.get("page", 1, type=int)
    por_pagina = request.args.get("per_page", 5, type=int)

    offset = (pagina - 1) * por_pagina

    conn = get_db_connection()

    publicaciones = conn.execute(
        """
        SELECT
            publicaciones.id,
            publicaciones.titulo,
            publicaciones.contenido,
            publicaciones.fecha_creacion,
            usuarios.nombre_usuario

        FROM publicaciones

        INNER JOIN usuarios
        ON publicaciones.usuario_id = usuarios.id

        ORDER BY publicaciones.id DESC

        LIMIT ?
        OFFSET ?
        """,
        (por_pagina, offset)
    ).fetchall()

    conn.close()

    datos = []

    for p in publicaciones:
        datos.append({
            "id": p["id"],
            "titulo": p["titulo"],
            "contenido": p["contenido"],
            "autor": p["nombre_usuario"],
            "fecha": p["fecha_creacion"]
        })

    return jsonify({
        "pagina": pagina,
        "por_pagina": por_pagina,
        "datos": datos
    })

# ==========================
# ACTUALIZAR
# ==========================

@app.route("/api/publicaciones/<int:id>", methods=["PUT"])
def actualizar_publicacion(id):

    data = request.get_json()

    titulo = data.get("titulo")
    contenido = data.get("contenido")

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        UPDATE publicaciones
        SET titulo=?, contenido=?
        WHERE id=?
        """,
        (titulo, contenido, id)
    )

    conn.commit()

    if cursor.rowcount == 0:
        conn.close()

        return jsonify({
            "error": "Publicación no encontrada"
        }), 404

    conn.close()

    cache.clear()

    return jsonify({
        "mensaje": "Publicación actualizada correctamente"
    })

# ==========================
# ELIMINAR
# ==========================

@app.route("/api/publicaciones/<int:id>", methods=["DELETE"])
def eliminar_publicacion(id):

    conn = get_db_connection()

    cursor = conn.cursor()

    cursor.execute(
        "DELETE FROM publicaciones WHERE id=?",
        (id,)
    )

    conn.commit()

    if cursor.rowcount == 0:

        conn.close()

        return jsonify({
            "error": "Publicación no encontrada"
        }), 404

        conn.close()

    cache.clear()

    return jsonify({
        "mensaje": "Publicación eliminada correctamente"
    })


# ==========================
# EJECUCIÓN
# ==========================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)