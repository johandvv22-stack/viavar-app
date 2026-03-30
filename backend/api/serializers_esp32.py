from rest_framework import serializers
from .models import Esp32Slave, Esp32Log, Esp32Comando

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
    posicion_bandeja = serializers.CharField(required=False, allow_blank=True)