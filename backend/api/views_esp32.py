from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Maquina, Esp32Slave, Esp32Log, Esp32Comando
from .serializers_esp32 import (
    Esp32SlaveSerializer, Esp32LogSerializer, Esp32ComandoSerializer,
    Esp32SlaveUpdateSerializer, Esp32LogCreateSerializer
)
from .permissions import IsAdminOrOperario

class Esp32SlaveViewSet(viewsets.ModelViewSet):
    """
    Vista para gestionar esclavas (bandejas) de una máquina.
    Solo admin puede modificar; operario puede ver.
    """
    queryset = Esp32Slave.objects.all()
    serializer_class = Esp32SlaveSerializer
    permission_classes = [IsAuthenticated, IsAdminOrOperario]

    def get_queryset(self):
        queryset = super().get_queryset()
        maquina_id = self.request.query_params.get('maquina')
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        return queryset

    @action(detail=True, methods=['post'])
    def enviar_comando(self, request, pk=None):
        """Enviar un comando a una esclava específica."""
        slave = self.get_object()
        comando = request.data.get('comando')
        parametros = request.data.get('parametros', {})
        if comando not in dict(Esp32Comando.COMANDO_CHOICES):
            return Response({'error': 'Comando inválido'}, status=status.HTTP_400_BAD_REQUEST)

        comando_obj = Esp32Comando.objects.create(
            maquina=slave.maquina,
            slave=slave,
            comando=comando,
            parametros=parametros
        )
        return Response(Esp32ComandoSerializer(comando_obj).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='actualizar-estado')
    def actualizar_estado(self, request):
        """Endpoint para que la ESP32 actualice el estado de una o varias esclavas."""
        data = request.data
        if not isinstance(data, list):
            data = [data]

        updated = []
        errors = []
        maquina_codigo = request.query_params.get('maquina_codigo') or request.data.get('maquina_codigo')

        for item in data:
            serializer = Esp32SlaveUpdateSerializer(data=item)
            if not serializer.is_valid():
                errors.append({'data': item, 'errors': serializer.errors})
                continue

            try:
                slave = Esp32Slave.objects.get(
                    maquina__codigo=maquina_codigo,
                    posicion=serializer.validated_data['posicion']
                )
            except Esp32Slave.DoesNotExist:
                errors.append({'data': item, 'errors': 'Esclava no encontrada'})
                continue

            for field, value in serializer.validated_data.items():
                if field != 'posicion':
                    setattr(slave, field, value)
            slave.ultima_conexion = timezone.now()
            slave.save()
            updated.append(slave.id)

        return Response({
            'updated': updated,
            'errors': errors
        }, status=status.HTTP_200_OK if not errors else status.HTTP_207_MULTI_STATUS)


class Esp32LogViewSet(viewsets.ModelViewSet):
    """Vista para logs de ESP32."""
    queryset = Esp32Log.objects.all().order_by('-timestamp')
    serializer_class = Esp32LogSerializer
    permission_classes = [IsAuthenticated, IsAdminOrOperario]

    def get_queryset(self):
        queryset = super().get_queryset()
        maquina_id = self.request.query_params.get('maquina')
        slave_id = self.request.query_params.get('slave')
        nivel = self.request.query_params.get('nivel')
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if slave_id:
            queryset = queryset.filter(slave_id=slave_id)
        if nivel:
            queryset = queryset.filter(nivel=nivel)
        return queryset

    @action(detail=False, methods=['post'])
    def crear_desde_esp32(self, request):
        """Endpoint para que la ESP32 envíe logs."""
        serializer = Esp32LogCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        maquina_codigo = request.query_params.get('maquina_codigo')

        if not maquina_codigo:
            return Response({'error': 'Se requiere maquina_codigo'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            maquina = Maquina.objects.get(codigo=maquina_codigo)
        except Maquina.DoesNotExist:
            return Response({'error': 'Máquina no encontrada'}, status=status.HTTP_404_NOT_FOUND)

        slave = None
        posicion = data.get('posicion_bandeja')
        if posicion:
            try:
                slave = Esp32Slave.objects.get(maquina=maquina, posicion=posicion)
            except Esp32Slave.DoesNotExist:
                pass

        log = Esp32Log.objects.create(
            maquina=maquina,
            slave=slave,
            nivel=data['nivel'],
            mensaje=data['mensaje'],
            datos_extra=data.get('datos_extra', {})
        )
        return Response(Esp32LogSerializer(log).data, status=status.HTTP_201_CREATED)


class Esp32ComandoViewSet(viewsets.ModelViewSet):
    """Vista para que la ESP32 obtenga comandos pendientes."""
    queryset = Esp32Comando.objects.all().order_by('creado_en')
    serializer_class = Esp32ComandoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        maquina_id = self.request.query_params.get('maquina')
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id, ejecutado=False)
        return queryset

    @action(detail=True, methods=['post'])
    def reportar_respuesta(self, request, pk=None):
        """La ESP32 reporta la respuesta de un comando."""
        comando = self.get_object()
        respuesta = request.data.get('respuesta', {})
        comando.respuesta = respuesta
        comando.ejecutado = True
        comando.ejecutado_en = timezone.now()
        comando.save()
        return Response({'status': 'ok'})