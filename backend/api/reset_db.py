# reset_db.py
import os
import sqlite3
import sys

print('=== RESETEO COMPLETO DE BASE DE DATOS ===')

# 1. Crear/sobrescribir db.sqlite3
print('1. Creando base de datos...')
if os.path.exists('db.sqlite3'):
    os.remove('db.sqlite3')
    print('   Base de datos anterior eliminada')

conn = sqlite3.connect('db.sqlite3')
print('   Base de datos vacía creada')

# 2. Crear tabla para migraciones (que Django necesita)
print('\\n2. Creando tabla de migraciones...')
conn.execute('''
    CREATE TABLE django_migrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        applied DATETIME NOT NULL
    )
''')
conn.commit()
conn.close()
print('   Tabla django_migrations creada')

print('\\n=== LISTO ===')
print('Ahora ejecuta estos comandos:')
print('1. python manage.py migrate')
print('2. python manage.py createsuperuser')
print('3. python manage.py runserver')