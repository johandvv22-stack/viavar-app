# recrear_migraciones.py
import os

print("🔄 RECREANDO ARCHIVOS DE MIGRACIÓN")
print("=" * 50)

# 1. Limpiar completamente migrations
migrations_dir = "api/migrations"
if os.path.exists(migrations_dir):
    for item in os.listdir(migrations_dir):
        item_path = os.path.join(migrations_dir, item)
        if os.path.isfile(item_path):
            os.remove(item_path)
        elif os.path.isdir(item_path):
            import shutil
            shutil.rmtree(item_path)

# 2. Crear __init__.py limpio
with open(os.path.join(migrations_dir, "__init__.py"), "w") as f:
    f.write("")

print("✅ Migraciones limpiadas")

# 3. Verificar que models.py no tenga errores
print("\n🔍 VERIFICANDO models.py...")
try:
    with open("api/models.py", "r", encoding="utf-8") as f:
        content = f.read()
    
    # Buscar caracteres nulos
    if '\x00' in content:
        print("❌ models.py tiene caracteres nulos")
        # Crear backup y nuevo
        os.rename("api/models.py", "api/models.py.corrupt")
        print("✅ models.py movido a backup")
    else:
        print("✅ models.py parece limpio")
        
except Exception as e:
    print(f"⚠️ Error leyendo models.py: {e}")

print("\n🎯 Ahora ejecuta:")
print("   python manage.py makemigrations api")
print("   python manage.py migrate")