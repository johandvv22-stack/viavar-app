import datetime
from rest_framework import serializers
from .models import Visita, InventarioMaquina, Producto, Maquina
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.db.models import Sum  # ← AGREGAR ESTA LÍNEA
from django.contrib.auth.password_validation import validate_password
from .models import *

# ==================== AUTH ====================
class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    
    def validate(self, data):
        username = data.get('username')
        password = data.get('password')
        
        if username and password:
            user = authenticate(username=username, password=password)
            if user:
                if not user.is_active:
                    raise serializers.ValidationError("Usuario inactivo.")
                data['user'] = user
            else:
                raise serializers.ValidationError("Credenciales inválidas.")
        else:
            raise serializers.ValidationError("Debe proporcionar username y password.")
        
        return data

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])

# ==================== MODELS ====================
class UsuarioSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, style={'input_type': 'password'})
    
    class Meta:
        model = Usuario
        fields = [
            'id', 'username', 'email', 'rol', 'telefono',
            'first_name', 'last_name', 'password', 'is_active',
            'is_staff', 'is_superuser', 'date_joined', 'last_login',
            'fecha_creacion'
        ]
        read_only_fields = ['date_joined', 'last_login', 'fecha_creacion']
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True}
        }
    
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = Usuario(**validated_data)
        if password:
            user.set_password(password)
        user.save()
        return user
    
    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance

class MaquinaSerializer(serializers.ModelSerializer):
    porcentaje_surtido = serializers.ReadOnlyField()
    ventas_hoy = serializers.SerializerMethodField()
    ganancia_hoy = serializers.SerializerMethodField()
    
    class Meta:
        model = Maquina
        fields = '__all__'
        read_only_fields = ['fecha_creacion']
    
    def get_ventas_hoy(self, obj):
        from django.utils import timezone
        hoy = timezone.now().date()
        ventas = obj.ventas.filter(fecha__date=hoy)
        total = ventas.aggregate(total=Sum('total'))['total']
        return float(total) if total else 0
    
    def get_ganancia_hoy(self, obj):
        from django.utils import timezone
        hoy = timezone.now().date()
        ventas = obj.ventas.filter(fecha__date=hoy)
        total = ventas.aggregate(total=Sum('ganancia'))['total']
        return float(total) if total else 0

class ProductoSerializer(serializers.ModelSerializer):
    ganancia_unitaria = serializers.ReadOnlyField()
    
    class Meta:
        model = Producto
        fields = '__all__'
        read_only_fields = ['fecha_creacion']

class InventarioMaquinaSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    producto_codigo = serializers.CharField(source='producto.codigo', read_only=True)
    cantidad_faltante = serializers.ReadOnlyField()
    porcentaje_surtido = serializers.ReadOnlyField()
    cantidad_vendida = serializers.ReadOnlyField()
    
    class Meta:
        model = InventarioMaquina
        fields = '__all__'
        read_only_fields = ['fecha_actualizacion']

class VentaSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    producto_codigo = serializers.CharField(source='producto.codigo', read_only=True)
    
    class Meta:
        model = Venta
        fields = '__all__'
        read_only_fields = ['total', 'costo', 'ganancia']

class GastoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.username', read_only=True)
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    
    class Meta:
        model = Gasto
        fields = '__all__'
        read_only_fields = ['usuario', 'fecha_creacion']
    
    def to_internal_value(self, data):
        """Convierte los datos de entrada antes de la validación"""
        # Hacer una copia para no modificar el original
        data = data.copy() if hasattr(data, 'copy') else dict(data)
        
        # Eliminar fecha si viene para que use el default del modelo
        if 'fecha' in data:
            del data['fecha']
        
        return super().to_internal_value(data)
    
    def create(self, validated_data):
        # Asegurar que la fecha sea la actual
        validated_data['fecha'] = timezone.now().date()
        # Asignar el usuario automáticamente
        validated_data['usuario'] = self.context['request'].user
        return super().create(validated_data)
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Formatear fecha para mostrarla bien
        if instance.fecha:
            data['fecha'] = instance.fecha.isoformat()
        return data
        
class VisitaSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    operario_nombre = serializers.CharField(source='operario.username', read_only=True)
    
    class Meta:
        model = Visita
        fields = '__all__'
    
    def to_representation(self, instance):
        """Convertir fechas a string para evitar errores de serialización"""
        data = super().to_representation(instance)
        
        # Convertir fecha_programada de date a string si es necesario
        if instance.fecha_programada:
            if isinstance(instance.fecha_programada, datetime.date):
                data['fecha_programada'] = instance.fecha_programada.isoformat()
        
        # Convertir datetime a string
        if instance.fecha_inicio:
            if isinstance(instance.fecha_inicio, datetime.datetime):
                data['fecha_inicio'] = instance.fecha_inicio.isoformat()
        
        if instance.fecha_fin:
            if isinstance(instance.fecha_fin, datetime.datetime):
                data['fecha_fin'] = instance.fecha_fin.isoformat()
        
        return data

class ConteoSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    usuario_nombre = serializers.CharField(source='usuario.get_full_name', read_only=True)
    
    class Meta:
        model = Conteo
        fields = '__all__'

class ConteoDetalleSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='inventario.producto.nombre', read_only=True)
    codigo_espiral = serializers.CharField(source='inventario.codigo_espiral', read_only=True)
    
    class Meta:
        model = ConteoDetalle
        fields = '__all__'

class CierreMensualSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    responsable_nombre = serializers.CharField(source='responsable.get_full_name', read_only=True)
    
    class Meta:
        model = CierreMensual
        fields = '__all__'
        read_only_fields = ['fecha_creacion', 'fecha_cierre']

# ==================== REPORTES ====================
class ReporteVentasSerializer(serializers.Serializer):
    fecha_inicio = serializers.DateField(required=True)
    fecha_fin = serializers.DateField(required=True)
    maquina_id = serializers.IntegerField(required=False, allow_null=True)
    producto_id = serializers.IntegerField(required=False, allow_null=True)

class ReporteGananciasSerializer(serializers.Serializer):
    periodo = serializers.ChoiceField(
        choices=[('dia', 'Día'), ('semana', 'Semana'), ('mes', 'Mes'), ('anio', 'Año')],
        default='mes'
    )
    maquina_id = serializers.IntegerField(required=False, allow_null=True)

class FiltroInventarioSerializer(serializers.Serializer):
    maquina_id = serializers.IntegerField(required=False)
    producto_id = serializers.IntegerField(required=False)
    critico = serializers.BooleanField(default=False)  # Solo inventario < 20%

# ==================== ESP32 ====================
class LecturaSensorSerializer(serializers.Serializer):
    """Valida cada lectura individual del array"""
    posicion = serializers.CharField(max_length=10)
    cantidad = serializers.IntegerField(min_value=0)
    estado_sensor = serializers.CharField(max_length=20, required=False, default='ok')

class EstadoESPSerializer(serializers.Serializer):
    """Valida el objeto de estado de la ESP32"""
    memoria_ocupada = serializers.IntegerField(required=False, default=0)
    firmware = serializers.CharField(required=False, allow_blank=True, default='')
    batches_pendientes = serializers.IntegerField(required=False, default=0)

class RecibirConteoSerializer(serializers.Serializer):
    """Valida el payload completo que envía la ESP32"""
    maquina_codigo = serializers.CharField(max_length=50)
    batch_id = serializers.CharField(max_length=64, required=False)
    lecturas = serializers.ListField(
        child=LecturaSensorSerializer(),
        allow_empty=False
    )
    estado_esp = EstadoESPSerializer(required=False, default={})

class Esp32EstadoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Esp32Estado
        fields = ['estado', 'ultima_conexion', 'memoria_ocupada', 
                  'firmware_version', 'intervalo_actual', 'batch_pendientes']
# ==================== RECARGAS ====================
class RecargaSerializer(serializers.ModelSerializer):
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    # ELIMINAR responsable_nombre - NO EXISTE EN EL MODELO
    # responsable_nombre = serializers.CharField(source='responsable.username', read_only=True, default=None)
    
    class Meta:
        model = Recarga
        fields = [
            'id', 'maquina', 'maquina_codigo', 'maquina_nombre', 
            'producto', 'producto_nombre',
            'inventario', 'visita', 'fecha', 'cantidad', 'origen',
            'observaciones', 'costo_unitario', 'costo_total', 'precio_venta'
        ]
        read_only_fields = ['fecha']

class RecargaCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recarga
        fields = [
            'maquina', 'producto', 'inventario', 'visita',
            'cantidad', 'origen', 'observaciones',
            'costo_unitario', 'costo_total', 'precio_venta'
        ]
    
    def validate(self, data):
        # Validar que la cantidad sea positiva
        if data['cantidad'] <= 0:
            raise serializers.ValidationError("La cantidad debe ser mayor a 0")
        
        # Calcular costo_total si no viene
        if 'costo_total' not in data or data['costo_total'] == 0:
            costo_unitario = data.get('costo_unitario', 0)
            data['costo_total'] = costo_unitario * data['cantidad']
        
        # Si se especifica inventario, verificar que coincida con máquina y producto
        if 'inventario' in data and data['inventario']:
            inventario = data['inventario']
            if inventario.maquina != data['maquina']:
                raise serializers.ValidationError("El inventario no pertenece a la máquina especificada")
            if inventario.producto != data['producto']:
                raise serializers.ValidationError("El producto no coincide con el inventario")
        
        return data
# En api/serializers.py (agregar al final)

class Esp32SlaveSerializer(serializers.ModelSerializer):
    class Meta:
        model = Esp32Slave
        fields = [
            'id', 'posicion', 'codigo_producto', 'firmware_version',
            'ultima_conexion', 'estado', 'error_mensaje',
            'distancia_min', 'distancia_max', 'posiciones',
            'ultima_lectura', 'ultima_lectura_fecha'
        ]
        read_only_fields = ['id', 'ultima_conexion', 'estado', 'error_mensaje', 'ultima_lectura', 'ultima_lectura_fecha']

class Esp32LogSerializer(serializers.ModelSerializer):
    class Meta:
        model = Esp32Log
        fields = '__all__'
        read_only_fields = ['id', 'timestamp']

class Esp32ComandoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Esp32Comando
        fields = '__all__'
        read_only_fields = ['id', 'creado_en', 'ejecutado', 'ejecutado_en', 'respuesta']

# Serializer para actualizar estado de esclava desde ESP32
class Esp32SlaveUpdateSerializer(serializers.Serializer):
    posicion = serializers.CharField()
    estado = serializers.ChoiceField(choices=Esp32Slave.ESTADO_CHOICES, required=False)
    error_mensaje = serializers.CharField(required=False, allow_blank=True)
    firmware_version = serializers.CharField(required=False)
    ultima_lectura = serializers.JSONField(required=False)
    distancia_min = serializers.FloatField(required=False)
    distancia_max = serializers.FloatField(required=False)
    posiciones = serializers.ListField(child=serializers.CharField(), required=False)

# Serializer para enviar logs desde ESP32
class Esp32LogCreateSerializer(serializers.Serializer):
    nivel = serializers.ChoiceField(choices=['INFO', 'WARNING', 'ERROR'])
    mensaje = serializers.CharField()
    datos_extra = serializers.JSONField(required=False, default=dict)
    posicion_bandeja = serializers.CharField(required=False, allow_blank=True)  # opcional