import os
import sys
import psycopg2

print("🧹 Iniciando reset completo...")

# Configuración de PostgreSQL
DB_CONFIG = {
    'dbname': 'inventory_db',
    'user': 'postgres',
    'password': 'Admin123*',
    'host': 'localhost',
    'port': '5432'
}

try:
    # Conectar a PostgreSQL
    print("🔗 Conectando a PostgreSQL...")
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("✅ Conectado a PostgreSQL")
    
    # Lista de tablas a eliminar (todas las de Django)
    print("🗑️  Eliminando tablas existentes...")
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
    """)
    
    tables = cursor.fetchall()
    for table in tables:
        table_name = table[0]
        try:
            cursor.execute(f'DROP TABLE IF EXISTS "{table_name}" CASCADE;')
            print(f"   - Tabla {table_name} eliminada")
        except Exception as e:
            print(f"   - Error eliminando {table_name}: {e}")
    
    cursor.close()
    conn.close()
    
    # Eliminar migraciones
    print("\n📁 Limpiando migraciones...")
    api_migrations = os.path.join('api', 'migrations')
    if os.path.exists(api_migrations):
        for file in os.listdir(api_migrations):
            if file.endswith('.py') and file != '__init__.py':
                os.remove(os.path.join(api_migrations, file))
        print("✅ Migraciones eliminadas")
    
    print("\n" + "="*50)
    print("🎉 RESET COMPLETADO EXITOSAMENTE!")
    print("="*50)
    print("\n📝 Ahora ejecuta estos comandos:")
    print("1. python manage.py makemigrations")
    print("2. python manage.py migrate")
    print("3. python manage.py createsuperuser")
    print("4. python manage.py runserver")
    
except Exception as e:
    print(f"\n❌ ERROR: {e}")
    print("\n💡 Posibles soluciones:")
    print("1. Verifica que PostgreSQL esté corriendo")
    print("2. Verifica las credenciales en settings.py")
    print("3. Asegúrate de que psycopg2-binary está instalado")