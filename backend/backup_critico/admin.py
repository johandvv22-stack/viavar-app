from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _
from .models import *

# Desregistrar el modelo User por defecto si está registrado
try:
    from django.contrib.auth.models import User
    admin.site.unregister(User)
except:
    pass

# Configuración personalizada para nuestro modelo Usuario
@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):
    # Campos a mostrar en la lista
    list_display = ('username', 'email', 'rol', 'first_name', 'last_name', 'is_active', 'date_joined')
    
    # Filtros disponibles
    list_filter = ('rol', 'is_active', 'is_staff', 'is_superuser', 'date_joined')
    
    # Campos de búsqueda
    search_fields = ('username', 'email', 'first_name', 'last_name', 'telefono')
    
    # Campos a mostrar en el formulario de edición
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Información personal'), {'fields': ('first_name', 'last_name', 'email', 'telefono')}),
        (_('Permisos'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        (_('Roles importantes'), {'fields': ('rol',)}),
        (_('Fechas importantes'), {'fields': ('last_login', 'date_joined', 'fecha_creacion')}),
    )
    
    # Campos a mostrar en el formulario de creación
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'rol', 'password1', 'password2'),
        }),
    )
    
    # Ordenamiento
    ordering = ('-date_joined',)
    
    # Solo lectura
    readonly_fields = ('last_login', 'date_joined', 'fecha_creacion')

# Configuración básica para otros modelos
@admin.register(Maquina)
class MaquinaAdmin(admin.ModelAdmin):
    list_display = ('codigo', 'nombre', 'ubicacion', 'estado', 'fecha_instalacion', 'capacidad_total')
    list_filter = ('estado', 'fecha_instalacion')
    search_fields = ('codigo', 'nombre', 'ubicacion')
    readonly_fields = ('porcentaje_surtido',)

@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ('codigo', 'nombre', 'categoria', 'precio_compra', 'precio_venta_sugerido', 'ganancia_unitaria', 'estado')
    list_filter = ('categoria', 'estado')
    search_fields = ('codigo', 'nombre', 'descripcion')

@admin.register(InventarioMaquina)
class InventarioMaquinaAdmin(admin.ModelAdmin):
    list_display = ('maquina', 'producto', 'codigo_espiral', 'stock_actual', 'stock_maximo', 'porcentaje_surtido', 'precio_venta')
    list_filter = ('maquina',)
    search_fields = ('maquina__codigo', 'producto__nombre', 'codigo_espiral')

@admin.register(Venta)
class VentaAdmin(admin.ModelAdmin):
    list_display = ('fecha', 'maquina', 'producto', 'cantidad', 'total', 'ganancia')
    list_filter = ('fecha', 'maquina')
    date_hierarchy = 'fecha'
    readonly_fields = ('total', 'costo', 'ganancia')

@admin.register(Gasto)
class GastoAdmin(admin.ModelAdmin):
    list_display = ('tipo', 'descripcion', 'valor', 'maquina', 'usuario', 'fecha')
    list_filter = ('tipo', 'fecha', 'maquina')
    date_hierarchy = 'fecha'

@admin.register(Visita)
class VisitaAdmin(admin.ModelAdmin):
    list_display = ('maquina', 'operario', 'estado', 'fecha_inicio', 'fecha_fin', 'total_ventas')
    list_filter = ('estado', 'fecha_inicio')
    date_hierarchy = 'fecha_inicio'

@admin.register(Conteo)
class ConteoAdmin(admin.ModelAdmin):
    list_display = ('maquina', 'tipo', 'fecha_hora', 'usuario')
    list_filter = ('tipo', 'fecha_hora')
    date_hierarchy = 'fecha_hora'

@admin.register(CierreMensual)
class CierreMensualAdmin(admin.ModelAdmin):
    list_display = ('maquina', 'mes', 'año', 'ventas_totales', 'ganancia_neta')
    list_filter = ('mes', 'año', 'maquina')

# Registrar modelos simples
admin.site.register(ConteoDetalle)