from flask import Flask, jsonify, request
from flask_cors import CORS
import sqlite3

app = Flask(__name__)
CORS(app)

DATABASE = 'trendvibe.db'

def conectar_db():
    """Establece conexión con la base de datos y retorna filas tipo diccionario."""
    conexion = sqlite3.connect(DATABASE)
    conexion.row_factory = sqlite3.Row
    return conexion

def inicializar_db():
    """Crea las tablas en 3FN e inserta datos iniciales si la DB está vacía."""
    with conectar_db() as conexion:
        # 1. Crear tabla de Categorías
        conexion.execute('''
            CREATE TABLE IF NOT EXISTS categorias (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL UNIQUE
            )
        ''')
        
        # 2. Crear tabla de Productos (Garantizando Integridad Referencial)
        conexion.execute('''
            CREATE TABLE IF NOT EXISTS productos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL,
                precio REAL NOT NULL,
                categoria_id INTEGER,
                FOREIGN KEY (categoria_id) REFERENCES categorias(id)
            )
        ''')
        
        # Insertar categorías base para ropa urbana si no existen
        cursor = conexion.cursor()
        cursor.execute("SELECT COUNT(*) FROM categorias")
        if cursor.fetchone()[0] == 0:
            cursor.execute("INSERT INTO categorias (nombre) VALUES ('Streetwear')")
            cursor.execute("INSERT INTO categorias (nombre) VALUES ('Hoodies')")
            cursor.execute("INSERT INTO categorias (nombre) VALUES ('Pantalones')")
            
            # Insertar productos relacionados dinámicamente mediante subconsultas SQL
            cursor.execute("INSERT INTO productos (nombre, precio, categoria_id) VALUES ('Chaqueta Denim Oversize', 45.00, (SELECT id FROM categorias WHERE nombre='Streetwear'))")
            cursor.execute("INSERT INTO productos (nombre, precio, categoria_id) VALUES ('Sudadera Hoodie Black', 35.50, (SELECT id FROM categorias WHERE nombre='Hoodies'))")
            cursor.execute("INSERT INTO productos (nombre, precio, categoria_id) VALUES ('Pantalón Cargo Camuflado', 40.00, (SELECT id FROM categorias WHERE nombre='Pantalones'))")
            conexion.commit()

# Inicializamos la base de datos relacional al arrancar el script
inicializar_db()

# ==================== ENDPOINTS DE LA API (CRUD) ====================

@app.route('/')
def index():
    return "<h1>TrendVibe API Backend</h1><p>Servidor con persistencia en Base de Datos Relacional Operativa.</p>"

# READ: Obtener todos los productos combinando tablas (INNER JOIN)
@app.route('/api/productos', methods=['GET'])
def obtener_productos():
    try:
        with conectar_db() as conexion:
            cursor = conexion.cursor()
            # Consulta relacional para traer el nombre de la categoría real
            cursor.execute('''
                SELECT p.id, p.nombre, p.precio, c.nombre AS categoria 
                FROM productos p
                INNER JOIN categorias c ON p.categoria_id = c.id
            ''')
            filas = cursor.fetchall()
            
            # Convertimos el resultado de la DB a una lista de diccionarios JSON
            productos_db = [dict(fila) for fila in filas]
            return jsonify(productos_db), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# CREATE: Endpoint para añadir un producto desde la App móvil
@app.route('/api/productos', methods=['POST'])
def crear_producto():
    datos = request.get_json()
    nombre = datos.get('nombre')
    precio = datos.get('precio')
    categoria_id = datos.get('categoria_id') # Id de la categoría seleccionada

    if not nombre or not precio or not categoria_id:
        return jsonify({"message": "Faltan datos obligatorios"}), 400

    with conectar_db() as conexion:
        cursor = conexion.cursor()
        cursor.execute("INSERT INTO productos (nombre, precio, categoria_id) VALUES (?, ?, ?)", 
                       (nombre, precio, categoria_id))
        conexion.commit()
        return jsonify({"message": "Producto guardado con éxito en la base de datos"}), 201

if __name__ == '__main__':
    app.run(debug=True, port=5000)