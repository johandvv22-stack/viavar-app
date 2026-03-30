# diagnosticar_dashboard.py
import os
import sys

# Agregar el path de Django
sys.path.append('.')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'inventory.settings')

import django
django.setup()

from api.models import *
from django.db.models import F, ExpressionWrapper, FloatField
from django.db.models.functions import Coalesce

print("🔍 DIAGNÓSTICO DEL ERROR DEL DASHBOARD")
print("=" * 50)

print("\n1. Verificando modelos y campos disponibles...")

# Verificar modelo Máquina
print("\n📦 Modelo Máquina:")
for field in Maquina._meta.get_fields():
    print(f"  {field.name}: {field.get_internal_type()}")

# Verificar modelo InventarioMaquina  
print("\n📦 Modelo InventarioMaquina:")
for field in InventarioMaquina._meta.get_fields():
    print(f"  {field.name}: {field.get_internal_type()}")

# Verificar si existe el campo porcentaje_surtido
print("\n🔍 Buscando campo 'porcentaje_surtido'...")
for model in [Maquina, InventarioMaquina, Producto, Visita]:
    fields = [f.name for f in model._meta.get_fields()]
    if 'porcentaje_surtido' in fields:
        print(f"✅ Encontrado en {model.__name__}")
    else:
        print(f"❌ No encontrado en {model.__name__}")

print("\n2. Probando cálculo de porcentaje_surtido...")
try:
    # Intentar calcular porcentaje_surtido
    inventarios = InventarioMaquina.objects.annotate(
        porcentaje=ExpressionWrapper(
            F('stock_actual') * 100.0 / F('stock_maximo'),
            output_field=FloatField()
        )
    ).filter(porcentaje__lt=30)  # Esto debería funcionar
    
    print(f"✅ Cálculo funciona: {inventarios.count()} inventarios < 30%")
    
except Exception as e:
    print(f"❌ Error en cálculo: {e}")