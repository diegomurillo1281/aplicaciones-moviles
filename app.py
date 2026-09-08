from flask_caching import Cache
import sqlite3
from flask import Flask, request, jsonify
from flask_cors import CORS
from flasgger import Swagger
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import (
    JWTManager, create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
from datetime import timedelta

app = Flask(__name__)

# Configuración de JWT
app.config["JWT_SECRET_KEY"] = "clave-secreta-trendvibe-2026"
# VIGENCIA DE 1 MINUTO PARA FORZAR LA RENOVACIÓN (HTTP 401) EN EL VIDEO
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(minutes=1)
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=7)

jwt = JWTManager(app)
swagger = Swagger(app)

cache = Cache(
    app,
    config={"CACHE_TYPE": "SimpleCache"}
)

# Permite que Flutter Web / Emulador puedan consumir la API
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
        client_uuid TEXT UNIQUE,
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
    data = request.get_json()

    if not data:
        return jsonify({"error": "No se enviaron datos"}), 400

    nombre = data.get("nombre_usuario")
    correo = data.get("correo")
    password = data.get("contrasena")

    # Validación con estado 422 para consistencia de campos
    errors = {}
    if not nombre or str(nombre).strip() == "":
        errors["nombre_usuario"] = "El nombre de usuario es obligatorio"
    if not correo or str(correo).strip() == "":
        errors["correo"] = "El correo electrónico es obligatorio"
    if not password or str(password).strip() == "":
        errors["contrasena"] = "La contraseña es obligatoria"

    if errors:
        return jsonify({"message": "Error de validación", "errors": errors}), 422

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
# LOGIN CON JWT
# ==========================

@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.get_json()

    if not data:
        return jsonify({"error": "No se enviaron datos"}), 400

    correo = data.get("correo")
    password = data.get("contrasena")

    if not correo or not password:
        return jsonify({
            "errors": {
                "correo": "Correo requerido" if not correo else "",
                "contrasena": "Contraseña requerida" if not password else ""
            }
        }), 422

    conn = get_db_connection()
    usuario = conn.execute(
        "SELECT * FROM usuarios WHERE correo=?",
        (correo,)
    ).fetchone()
    conn.close()

    if usuario is None or not check_password_hash(usuario["contrasena"], password):
        return jsonify({
            "error": "Credenciales incorrectas"
        }), 401

    # Generación de tokens JWT
    identity_str = str(usuario["id"])
    access_token = create_access_token(identity=identity_str)
    refresh_token = create_refresh_token(identity=identity_str)

    return jsonify({
        "mensaje": "Inicio de sesión exitoso",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "usuario": {
            "id": usuario["id"],
            "nombre_usuario": usuario["nombre_usuario"],
            "correo": usuario["correo"]
        }
    }), 200


# ==========================
# RENOVACIÓN DE TOKEN (REFRESH)
# ==========================

@app.route("/api/auth/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    new_access_token = create_access_token(identity=identity)
    return jsonify({
        "access_token": new_access_token
    }), 200


# ==========================
# CREAR PUBLICACIÓN (PROTEGIDA + VALIDACIÓN 422)
# ==========================

@app.route("/api/publicaciones", methods=["POST"])
@jwt_required()
def crear_publicacion():
    data = request.get_json() or {}

    usuario_id = data.get("usuario_id")
    titulo = data.get("titulo")
    contenido = data.get("contenido")
    client_uuid = data.get("client_uuid")

    # Validación 422 de campos para la demostración en video
    errors = {}
    if not titulo or str(titulo).strip() == "":
        errors["titulo"] = "El título de la publicación es obligatorio."
    if not contenido or str(contenido).strip() == "":
        errors["contenido"] = "El contenido no puede estar vacío."

    if errors:
        return jsonify({"message": "Error de validación", "errors": errors}), 422

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
        INSERT INTO publicaciones(usuario_id, titulo, contenido, client_uuid)
        VALUES(?,?,?,?)
        """, (usuario_id, titulo, contenido, client_uuid))

        conn.commit()
    except sqlite3.IntegrityError:
        # Previene duplicados en caso de reintentos con la cola offline
        conn.close()
        return jsonify({"mensaje": "La publicación ya existe (idempotencia)"}), 200
    finally:
        conn.close()

    cache.clear()

    return jsonify({
        "mensaje": "Publicación creada correctamente"
    }), 201


# ==========================
# LISTAR PUBLICACIONES (PROTEGIDA)
# ==========================

@app.route("/api/publicaciones", methods=["GET"])
@jwt_required()
@cache.cached(timeout=30, query_string=True)
def listar_publicaciones():
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
# ACTUALIZAR (PROTEGIDA)
# ==========================

@app.route("/api/publicaciones/<int:id>", methods=["PUT"])
@jwt_required()
def actualizar_publicacion(id):
    data = request.get_json() or {}

    titulo = data.get("titulo")
    contenido = data.get("contenido")

    if not titulo or not contenido:
        return jsonify({
            "errors": {
                "titulo": "Título obligatorio",
                "contenido": "Contenido obligatorio"
            }
        }), 422

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
# ELIMINAR (PROTEGIDA)
# ==========================

@app.route("/api/publicaciones/<int:id>", methods=["DELETE"])
@jwt_required()
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