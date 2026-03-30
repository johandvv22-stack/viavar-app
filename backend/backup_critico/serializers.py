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
    usuario_nombre = serializers.CharField(source='usuario.get_full_name', read_only=True)
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True, allow_null=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True, allow_null=True)
    
    class Meta:
        model = Gasto
        fields = '__all__'
        read_only_fields = ['fecha_creacion', 'usuario']

class VisitaSerializer(serializers.ModelSerializer):
    maquina_nombre = serializers.CharField(source='maquina.nombre', read_only=True)
    maquina_codigo = serializers.CharField(source='maquina.codigo', read_only=True)
    operario_nombre = serializers.CharField(source='operario.get_full_name', read_only=True)
    operario_username = serializers.CharField(source='operario.username', read_only=True)
    duracion = serializers.ReadOnlyField()
    
    class Meta:
        model = Visita
        fields = '__all__'
        read_only_fields = ['total_ventas', 'total_ganancias', 'fecha_creacion']

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