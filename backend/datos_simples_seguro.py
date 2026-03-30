# datos_simples_seguro.py
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'inventory.settings')

import django
django.setup()

from api.models import *
from django.contrib.auth.hashers import make_password
from datetime import datetime, timedelta
import random

print("🎯 CREANDO DATOS SIMPLES Y SEGUROS")
print("=" * 50)

def paso_usuarios():
    """Crear usuarios básicos"""
    print("\n👥 CREANDO USUARIOS...")
    
    # Usuario admin
    admin, created = Usuario.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@empresa.com',
            'rol': 'admin',
            'first_name': 'Administrador',
            'last_name': 'Sistema',
            'is_staff': True,
            'is_superuser': True
        }
    )
    if created:
        admin.set_password('Admin123*')
        admin.save()
        print("✅ Usuario admin creado")
    else:
        # Asegurar que tiene rol correcto
        if admin.rol != 'admin':
            admin.rol = 'admin'
            admin.is_staff = True
            admin.is_superuser = True
            admin.save()
            print("✅ Rol admin corregido")
        else:
            print("✅ Usuario admin ya existe (rol correcto)")
    
    # Usuario operario
    operario, created = Usuario.objects.get_or_create(
        username='operario',
        defaults={
            'email': 'operario@empresa.com',
            'rol': 'operario',
            'first_name': 'Carlos',
            'last_name': 'Rodríguez'
        }
    )
    if created:
        operario.set_password('Operario123*')
        operario.save()
        print("✅ Usuario operario creado")
    else:
        print("✅ Usuario operario ya existe")
    
    return {'admin': admin, 'operario': operario}

def paso_productos():
    """Crear 4 productos básicos"""
    print("\n📦 CREANDO PRODUCTOS BÁSICOS...")
    
    productos = [
        {
            'codigo': 'SNACK001',
            'nombre': 'Papas Margaritas',
            'categoria': 'paquete_grande',
            'precio_compra': 1500,
            'precio_venta_sugerido': 3000
        },
        {
            'codigo': 'SNACK002', 
            'nombre': 'Chocolatina Jet',
            'categoria': 'paquete_pequeno',
            'precio_compra': 800,
            'precio_venta_sugerido': 1500
        },
        {
            'codigo': 'BEB001',
            'nombre': 'Agua 500ml',
            'categoria': 'liquido_pequeno',
            'precio_compra': 1200,
            'precio_venta_sugerido': 2000
        },
        {
            'codigo': 'BEB002',
            'nombre': 'Gaseosa 350ml',
            'categoria': 'liquido_pequeno',
            'precio_compra': 1800,
            'precio_venta_sugerido': 3000
        }
    ]
    
    creados = 0
    for prod in productos:
        obj, created = Producto.objects.get_or_create(
            codigo=prod['codigo'],
            defaults={
                'nombre': prod['nombre'],
                'categoria': prod['categoria'],
                'precio_compra': prod['precio_compra'],
                'precio_venta_sugerido': prod['precio_venta_sugerido'],
                'estado': True
            }
        )
        if created:
            creados += 1
            print(f"  ✅ {prod['codigo']}: {prod['nombre']}")
    
    print(f"✅ Total productos: {Producto.objects.count()} ({creados} nuevos)")
    return Producto.objects.all()

def paso_maquinas():
    """Crear 2 máquinas básicas"""
    print("\n🏪 CREANDO MÁQUINAS BÁSICAS...")
    
    maquinas = [
        {
            'codigo': 'MAQ001',
            'nombre': 'Máquina Oficina',
            'ubicacion': 'Edificio A, Piso 3',
            'capacidad_total': 40,
            'estado': 'activa'
        },
        {
            'codigo': 'MAQ002',
            'nombre': 'Máquina Recepción',
            'ubicacion': 'Lobby principal',
            'capacidad_total': 35,
            'estado': 'activa'
        }
    ]
    
    maquina_objs = []
    for maq in maquinas:
        obj, created = Maquina.objects.get_or_create(
            codigo=maq['codigo'],
            defaults=maq
        )
        if created:
            print(f"  ✅ {maq['codigo']}: {maq['nombre']}")
        maquina_objs.append(obj)
    
    print(f"✅ Total máquinas: {Maquina.objects.count()}")
    return maquina_objs

def paso_inventarios(maquinas, productos):
    """Crear inventario básico"""
    print("\n📊 CREANDO INVENTARIO BÁSICO...")
    
    for maquina in maquinas:
        # Asignar todos los productos a cada máquina
        for i, producto in enumerate(productos):
            # Precio de venta específico para esta máquina (puede variar)
            precio_venta = float(producto.precio_venta_sugerido) * random.uniform(0.95, 1.05)
            
            InventarioMaquina.objects.get_or_create(
                maquina=maquina,
                producto=producto,
                defaults={
                    'codigo_espiral': f"ESP{i+1:03d}",
                    'stock_maximo': 10,
                    'stock_actual': random.randint(3, 8),  # Stock variable
                    'stock_surtido': 10,
                    'precio_venta': round(precio_venta, 2)
                }
            )
        print(f"  ✅ {maquina.codigo}: {len(productos)} productos asignados")
    
    print(f"✅ Total inventarios: {InventarioMaquina.objects.count()}")

def paso_datos_extra():
    """Crear algunos datos extra para hacer el dashboard interesante"""
    print("\n💰 CREANDO DATOS DE DEMOSTRACIÓN...")
    
    from django.utils import timezone
    import random
    
    # Obtener máquinas y productos
    maquinas = Maquina.objects.all()
    productos = list(Producto.objects.all())
    
    if not maquinas.exists() or not productos:
        print("⚠️  No hay máquinas o productos para crear datos extra")
        return
    
    # Crear algunas ventas de los últimos 7 días
    print("  📈 Creando ventas de demostración...")
    hoy = timezone.now()
    ventas_creadas = 0
    
    for dias_atras in range(7):
        fecha = hoy - timedelta(days=dias_atras)
        
        # 3-8 ventas por día
        for _ in range(random.randint(3, 8)):
            maquina = random.choice(maquinas)
            producto = random.choice(productos)
            inventario = InventarioMaquina.objects.filter(maquina=maquina, producto=producto).first()
            
            if inventario and inventario.stock_actual > 0:
                cantidad = random.randint(1, min(3, inventario.stock_actual))
                precio = inventario.precio_venta
                total = cantidad * precio
                costo = cantidad * producto.precio_compra
                ganancia = total - costo
                
                # Crear venta con hora aleatoria del día
                fecha_venta = fecha.replace(
                    hour=random.randint(8, 19),
                    minute=random.randint(0, 59),
                    second=random.randint(0, 59)
                )
                
                Venta.objects.create(
                    maquina=maquina,
                    producto=producto,
                    inventario=inventario,
                    cantidad=cantidad,
                    precio_unitario=precio,
                    total=total,
                    costo=costo,
                    ganancia=ganancia,
                    fecha=fecha_venta
                )
                
                # Actualizar stock
                inventario.stock_actual -= cantidad
                inventario.save()
                
                ventas_creadas += 1
    
    # Crear algunos gastos
    print("  💸 Creando gastos de demostración...")
    tipos = ['transporte', 'mantenimiento', 'operario', 'otros']
    
    for _ in range(5):
        Gasto.objects.create(
            tipo=random.choice(tipos),
            valor=random.randint(20000, 80000),
            descripcion=f"Gasto de {random.choice(['transporte', 'mantenimiento', 'operativo'])}",
            fecha=(hoy - timedelta(days=random.randint(0, 30))).date(),
            usuario=Usuario.objects.filter(rol='admin').first(),
            maquina=random.choice(maquinas) if random.choice([True, False]) else None
        )
    
    print(f"✅ {ventas_creadas} ventas creadas")
    print(f"✅ {Gasto.objects.count()} gastos creados")

def main():
    """Función principal"""
    print("🚀 INICIANDO CREACIÓN DE DATOS SIMPLES")
    print("=" * 50)
    
    try:
        # Paso 1: Usuarios
        usuarios = paso_usuarios()
        
        # Paso 2: Productos
        productos = paso_productos()
        
        # Paso 3: Máquinas
        maquinas = paso_maquinas()
        
        # Paso 4: Inventarios
        paso_inventarios(maquinas, productos)
        
        # Paso 5: Datos extra (opcional)
        crear_extra = input("\n¿Crear datos de demostración? (ventas, gastos) [S/n]: ").strip().lower()
        if crear_extra in ['s', 'si', 'sí', '']:
            paso_datos_extra()
        
        # Resumen final
        print("\n" + "="*50)
        print("🎯 DATOS CREADOS EXITOSAMENTE!")
        print("="*50)
        
        print(f"\n📊 RESUMEN:")
        print(f"   👥 Usuarios: {Usuario.objects.count()}")
        print(f"   📦 Productos: {Producto.objects.count()}")
        print(f"   🏪 Máquinas: {Maquina.objects.count()}")
        print(f"   📊 Inventarios: {InventarioMaquina.objects.count()}")
        print(f"   💰 Ventas: {Venta.objects.count()}")
        print(f"   💸 Gastos: {Gasto.objects.count()}")
        
        print("\n🔑 CREDENCIALES:")
        print("   Admin: usuario='admin', password='Admin123*'")
        print("   Operario: usuario='operario', password='Operario123*'")
        
        print("\n🎯 PARA PROBAR:")
        print("   python test_api_completo.py")
        print("   # El dashboard debería mostrar datos interesantes")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        print("\n💡 SOLUCIÓN: Verifica que los modelos estén correctos")

if __name__ == "__main__":
    main()