import requests
import json
import sys

print(" SISTEMA DE INVENTARIO - PRUEBA COMPLETA DE API")
print("=" * 60)

def safe_get(data, key, default="N/A"):
    """Obtener valor de forma segura"""
    if isinstance(data, dict):
        return data.get(key, default)
    return default

def print_section(title):
    print(f"\n{'='*50}")
    print(f" {title}")
    print(f"{'='*50}")

# ============ 1. AUTENTICACIÓN ============
print_section("1. AUTENTICACIÓN JWT")

try:
    # Login
    print(" Obteniendo token JWT...")
    login_response = requests.post(
        "http://localhost:8000/api/token/",
        json={"username": "admin", "password": "Admin123*"},
        timeout=10
    )
    
    if login_response.status_code != 200:
        print(f" Error en login: {login_response.status_code}")
        print(f"   {login_response.text}")
        sys.exit(1)
    
    token_data = login_response.json()
    access_token = token_data["access"]
    user_info = token_data["user"]
    
    print(f" Login exitoso!")
    print(f"   Usuario: {user_info['username']}")
    print(f"   Rol: {safe_get(user_info, 'rol')}")
    print(f"   Token: {access_token[:30]}...")
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
except requests.exceptions.ConnectionError:
    print(" No se puede conectar al servidor")
    print("   Ejecuta: python manage.py runserver")
    sys.exit(1)
except Exception as e:
    print(f" Error inesperado: {e}")
    sys.exit(1)

# ============ 2. PROBAR ENDPOINTS ============
print_section("2. ENDPOINTS PRINCIPALES")

endpoints = [
    ("/api/dashboard/", "Dashboard administrativo"),
    ("/api/maquinas/", "Listado de máquinas"),
    ("/api/maquinas/estado/", "Estado de máquinas"),
    ("/api/productos/", "Catálogo de productos"),
    ("/api/inventario/", "Inventario general"),
    ("/api/ventas/", "Ventas registradas"),
    ("/api/gastos/", "Gastos operativos"),
    ("/api/visitas/", "Historial de visitas"),
]

for url, name in endpoints:
    print(f"\n {name}")
    print(f"   URL: {url}")
    
    try:
        response = requests.get(
            f"http://localhost:8000{url}",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # Manejar diferentes tipos de respuesta de forma SEGURA
            if isinstance(data, list):
                print(f"    OK: {len(data)} registros")
                if data:
                    # Mostrar primeros 2 elementos de forma segura
                    for i in range(min(2, len(data))):
                        item = data[i]
                        if isinstance(item, dict):
                            # Buscar campos comunes para mostrar
                            display_fields = ["nombre", "codigo", "id", "maquina"]
                            for field in display_fields:
                                if field in item:
                                    value = item[field]
                                    print(f"      {i+1}. {field}: {value}")
                                    break
                            else:
                                # Si no encuentra campos comunes, mostrar tipo
                                print(f"      {i+1}. {type(item).__name__}")
                        else:
                            print(f"      {i+1}. {str(item)[:50]}...")
            
            elif isinstance(data, dict):
                print(f"    OK: Respuesta es objeto/diccionario")
                # Mostrar primeras 3 keys de forma segura
                keys = list(data.keys())[:3] if isinstance(data, dict) else []
                if keys:
                    print(f"      Campos principales: {', '.join(keys)}")
                else:
                    print(f"      Estructura: {type(data).__name__}")
            
            else:
                print(f"    OK: Tipo de dato: {type(data).__name__}")
                
        elif response.status_code == 403:
            print(f"     Acceso denegado (sin permisos para este rol)")
        elif response.status_code == 404:
            print(f"     Endpoint no encontrado (posiblemente no implementado)")
        else:
            print(f"    Error {response.status_code}: {response.text[:100]}...")
            
    except Exception as e:
        print(f"    Error al conectar: {e}")

# ============ 3. VERIFICAR PERMISOS POR ROL ============
print_section("3. VERIFICACIÓN DE PERMISOS")

print("\n Probando acceso con usuario admin...")
print("   (Debería tener acceso a todo)")

# Contar endpoints exitosos
success_count = 0
total_endpoints = len(endpoints)

for url, name in endpoints:
    try:
        response = requests.get(
            f"http://localhost:8000{url}",
            headers=headers,
            timeout=5
        )
        if response.status_code == 200:
            success_count += 1
    except:
        pass

print(f"\n RESULTADOS:")
print(f"   Endpoints probados: {total_endpoints}")
print(f"   Endpoints exitosos: {success_count}")
print(f"   Porcentaje éxito: {(success_count/total_endpoints)*100:.1f}%")

if success_count == total_endpoints:
    print(" BACKEND FUNCIONANDO CORRECTAMENTE")
elif success_count >= total_endpoints * 0.7:
    print(" BACKEND FUNCIONANDO (algunos endpoints pendientes)")
else:
    print("  REVISAR ENDPOINTS FALLIDOS")

print("\n" + "="*60)
print(" PRÓXIMOS PASOS:")
print("   1. Desarrollar frontend Flutter")
print("   2. Integrar con sistema ESP32 de conteo")
print("   3. Desplegar en producción")
