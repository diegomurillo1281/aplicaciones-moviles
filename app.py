import os
import sqlite3
from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.config['SECRET_KEY'] = 'tu_clave_secreta_para_tokens_aqui'
DATABASE = 'trendvibe.db'

def get_db_connection():
    """Establece conexión con la base de datos SQLite."""
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row  # Permite acceder a las columnas por nombre como un diccionario
    return conn

def init_db():
    """Crea las tablas bajo la 3ra Forma Normal (3FN) si no existen."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Activar el soporte de llaves foráneas en SQLite
    cursor.execute("PRAGMA foreign_keys = ON;")
    
    # Tabla de Usuarios
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre_usuario TEXT UNIQUE NOT NULL,
            correo TEXT UNIQUE NOT NULL,
            contrasena TEXT NOT NULL,
            fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Tabla de Publicaciones / Contenido (Relación 1 a Muchos con Usuarios)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS publicaciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            titulo TEXT NOT NULL,
            contenido TEXT NOT NULL,
            fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
        )
    ''')
    
    conn.commit()
    conn.close()

# Inicializar la base de datos al arrancar el servidor
init_db()

# ==========================================
#               ENDPOINTS API
# ==========================================

@app.route('/')
def index():
    return jsonify({"proyecto": "TrendVibe API", "estado": "Operativo"})

# 1. Registro de Usuarios (Seguridad de la información)
@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or 'nombre_usuario' not in data or 'correo' not in data or 'contrasena' not in data:
        return jsonify({"error": "Faltan campos obligatorios"}), 400
    
    hashed_password = generate_password_hash(data['contrasena'], method='pbkdf2:sha256')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO usuarios (nombre_usuario, correo, contrasena) VALUES (?, ?, ?)',
            (data['nombre_usuario'], data['correo'], hashed_password)
        )
        conn.commit()
        return jsonify({"mensaje": "Usuario registrado exitosamente"}), 201
    except sqlite3.IntegrityError:
        return jsonify({"error": "El usuario o correo ya se encuentra registrado"}), 400
    finally:
        conn.close()

# 2. Inicio de Sesión (Autenticación requerida)
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or 'correo' not in data or 'contrasena' not in data:
        return jsonify({"error": "Faltan credenciales"}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    usuario = cursor.execute('SELECT * FROM usuarios WHERE correo = ?', (data['correo'],)).fetchone()
    conn.close()
    
    if usuario and check_password_hash(usuario['contrasena'], data['contrasena']):
        return jsonify({
            "mensaje": "Inicio de sesión exitoso",
            "usuario": {
                "id": usuario['id'],
                "nombre_usuario": usuario['nombre_usuario'],
                "correo": usuario['correo']
            }
        }), 200
        
    return jsonify({"error": "Credenciales incorrectas"}), 401


# ==========================================
#          CRUD DE PUBLICACIONES (CON PAGINACIÓN)
# ==========================================

# C-R-U-D: CREAR (POST)
@app.route('/api/publicaciones', methods=['POST'])
def crear_publicacion():
    data = request.get_json()
    if not data or 'usuario_id' not in data or 'titulo' not in data or 'contenido' not in data:
        return jsonify({"error": "Campos obligatorios faltantes"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO publicaciones (usuario_id, titulo, contenido) VALUES (?, ?, ?)',
            (data['usuario_id'], data['titulo'], data['contenido'])
        )
        conn.commit()
        return jsonify({"mensaje": "Publicación creada con éxito"}), 201
    except sqlite3.IntegrityError:
        return jsonify({"error": "Error de integridad. Verifique el usuario_id"}), 400
    finally:
        conn.close()

# C-R-U-D: LEER TODAS CON PAGINACIÓN (GET) -> Requerimiento de Optimización Obligatorio
@app.route('/api/publicaciones', methods=['GET'])
def obtener_publicaciones():
    # Optimización: Paginación mediante parámetros de URL (?page=1&per_page=5)
    pagina = request.args.get('page', 1, type=int)
    por_pagina = request.args.get('per_page', 5, type=int)
    offset = (pagina - 1) * por_pagina
    
    conn = get_db_connection()
    # Consulta SQL relacional estructurada utilizando un JOIN
    query = '''
        SELECT p.id, p.titulo, p.contenido, p.fecha_creacion, u.nombre_usuario 
        FROM publicaciones p
        JOIN usuarios u ON p.usuario_id = u.id
        ORDER BY p.fecha_creacion DESC
        LIMIT ? OFFSET ?
    '''
    publicaciones = conn.execute(query, (por_pagina, offset)).fetchall()
    conn.close()
    
    resultado = []
    for pub in publicaciones:
        resultado.append({
            "id": pub['id'],
            "titulo": pub['titulo'],
            "contenido": pub['contenido'],
            "fecha_creacion": pub['fecha_creacion'],
            "autor": pub['nombre_usuario']
        })
        
    return jsonify({
        "pagina": pagina,
        "por_pagina": por_pagina,
        "datos": resultado
    }), 200

# C-R-U-D: ACTUALIZAR (PUT)
@app.route('/api/publicaciones/<int:id>', methods=['PUT'])
def actualizar_publicacion(id):
    data = request.get_json()
    if not data or 'titulo' not in data or 'contenido' not in data:
        return jsonify({"error": "Campos faltantes"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        'UPDATE publicaciones SET titulo = ?, contenido = ? WHERE id = ?',
        (data['titulo'], data['contenido'], id)
    )
    conn.commit()
    filas_afectadas = cursor.rowcount
    conn.close()
    
    if filas_afectadas == 0:
        return jsonify({"error": "Publicación no encontrada"}), 404
        
    return jsonify({"mensaje": "Publicación actualizada con éxito"}), 200

# C-R-U-D: ELIMINAR (DELETE)
@app.route('/api/publicaciones/<int:id>', methods=['DELETE'])
def eliminar_publicacion(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM publicaciones WHERE id = ?', (id,))
    conn.commit()
    filas_afectadas = cursor.rowcount
    conn.close()
    
    if filas_afectadas == 0:
        return jsonify({"error": "Publicación no encontrada"}), 404
        
    return jsonify({"mensaje": "Publicación eliminada con éxito"}), 200

if __name__ == '__main__':
    app.run(debug=True, port=5000)