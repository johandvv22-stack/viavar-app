import requests
import json
from datetime import datetime

# Configuración - usa tu IP actual
BASE_URL = "http://192.168.80.14:8000/api"
login_url = f"{BASE_URL}/token/"
# IMPORTANTE: Usamos el endpoint correcto
endpoint_url = f"{BASE_URL}/esp32/v1/recibir/"

# Credenciales del usuario ESP32
credentials = {
    "username": "esp32_maq001",
    "password": "MAQ001_esp32_2026"
}

print("="*50)
print("PRUEBA DE ENDPOINT ESP32")
print("="*50)

# 1. Obtener token JWT
print("\n1. Obteniendo token JWT...")
try:
    response = requests.post(login_url, json=credentials, timeout=5)
    print(f"   Código: {response.status_code}")
    
    if response.status_code != 200:
        print(f"   ❌ Error: {response.text}")
        exit()
    
    token = response.json()["access"]
    print("   ✅ Token obtenido correctamente")
except Exception as e:
    print(f"   ❌ Error de conexión: {e}")
    exit()

# 2. Preparar payload SIMULADO (como si viniera de la ESP32)
print("\n2. Preparando datos de conteo...")

# IMPORTANTE: El username es esp32_maq001, entonces:
# El código de máquina debe ser MAQ001 (según la lógica en endpoint_que_si_funciona)
# porque hace: codigo_maquina = usuario.username.replace('esp32_', '').upper()

payload = {
    "maquina_codigo": "MAQ001",  # Debe coincidir con el username
    "batch_id": f"batch_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
    "lecturas": [
        {
            "posicion": "A11",
            "cantidad": 8,
            "estado_sensor": "ok"
        },
        {
            "posicion": "A12",
            "cantidad": 12,
            "estado_sensor": "ok"
        },
        {
            "posicion": "B11",
            "cantidad": 5,
            "estado_sensor": "ok"
        },
        {
            "posicion": "B12",
            "cantidad": 7,
            "estado_sensor": "ok"
        }
    ],
    "estado_esp": {
        "memoria_ocupada": 2048,
        "firmware": "v1.0.0",
        "batches_pendientes": 0
    }
}

print(f"   Batch ID: {payload['batch_id']}")
print(f"   Lecturas: {len(payload['lecturas'])}")

# 3. Enviar datos al endpoint
print("\n3. Enviando datos al endpoint...")
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

try:
    response = requests.post(endpoint_url, json=payload, headers=headers, timeout=10)
    print(f"   Código HTTP: {response.status_code}")
    
    print("\n4. Respuesta del servidor:")
    print("-"*30)
    try:
        response_json = response.json()
        print(json.dumps(response_json, indent=2, ensure_ascii=False))
    except:
        print(response.text)
    
    if response.status_code == 200:
        print("\n✅ ¡PRUEBA EXITOSA! El endpoint funciona correctamente.")
    else:
        print(f"\n❌ Error: {response.status_code}")
        
except Exception as e:
    print(f"   ❌ Error de conexión: {e}")

print("\n" + "="*50)