from rest_framework import viewsets, status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.exceptions import PermissionDenied
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Sum, Count, Avg, Q, F, ExpressionWrapper, FloatField
from django.db.models.functions import Coalesce as CoalesceFunc
from dateutil.relativedelta import relativedelta
from django.utils import timezone
from datetime import datetime, timedelta
import datetime
from django.utils import timezone
from django.db.models import Sum,Value, DecimalField,Count, Q, F, ExpressionWrapper, FloatField
from django.db.models import Value
from django.db.models.functions import Coalesce
from django.utils.dateparse import parse_date
import json

from .models import *
from .serializers import *
from .permissions import *
from .authentication import ESP32APIAuthentication
from .services import procesar_lecturas_esp32
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Visita, Maquina, InventarioMaquina, Recarga
from .serializers import VisitaSerializer, InventarioMaquinaSerializer
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
local_tz = ZoneInfo('America/Bogota')

# ==================== AUTHENTICATION ====================
class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            refresh = RefreshToken.for_user(user)
            
            user_data = {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'rol': user.rol,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'telefono': user.telefono,
            }
            
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': user_data
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        serializer = UsuarioSerializer(user)
        return Response(serializer.data)

# ==================== VIEWSETS ====================
class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer
    permission_classes = [IsAuthenticated]
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsAuthenticated]  # Solo admin puede modificar
        else:
            permission_classes = [IsAuthenticated]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        if self.request.user.rol == 'admin':
            return Usuario.objects.all()
        # Operarios solo pueden verse a sí mismos
        return Usuario.objects.filter(id=self.request.user.id)

class MaquinaViewSet(viewsets.ModelViewSet):
    queryset = Maquina.objects.all()
    serializer_class = MaquinaSerializer
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def estado(self, request):
        """Endpoint para estado de máquinas"""
        maquinas = Maquina.objects.all()
        data = []
        for maquina in maquinas:
            ultima_visita = maquina.visitas.filter(estado='completada').order_by('-fecha_fin').first()
            
            # Calcular ventas del día
            hoy = timezone.now().date()
            ventas_hoy = maquina.ventas.filter(
                fecha__date=hoy
            ).aggregate(
                total=Sum('total'),
                ganancia=Sum('ganancia')
            )
            
            # Calcular porcentaje de surtido dinámicamente
            porcentaje_surtido = 0
            inventarios = maquina.inventarios.all()
            if inventarios.exists():
                total_actual = sum(inv.stock_actual for inv in inventarios)
                total_maximo = sum(inv.stock_maximo for inv in inventarios)
                if total_maximo > 0:
                    porcentaje_surtido = (total_actual / total_maximo) * 100
            
            data.append({
                'id': maquina.id,
                'codigo': maquina.codigo,
                'nombre': maquina.nombre,
                'ubicacion': maquina.ubicacion,
                'estado': maquina.estado,
                'porcentaje_surtido': round(porcentaje_surtido, 2),
                'ultima_visita': ultima_visita.fecha_fin if ultima_visita else None,
                'ventas_hoy': ventas_hoy['total'] or 0,
                'ganancia_hoy': ventas_hoy['ganancia'] or 0,
            })
        return Response(data)
    
    @action(detail=True, methods=['get'])
    def inventario(self, request, pk=None):
        """Inventario completo de una máquina"""
        maquina = self.get_object()
        inventarios = maquina.inventarios.all()
        serializer = InventarioMaquinaSerializer(inventarios, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def reporte(self, request, pk=None):
        """Reporte detallado de una máquina"""
        maquina = self.get_object()
        
        # Ventas por periodo
        periodo = request.query_params.get('periodo', 'mes')
        hoy = timezone.now()
        
        if periodo == 'dia':
            fecha_inicio = hoy.replace(hour=0, minute=0, second=0, microsecond=0)
        elif periodo == 'semana':
            fecha_inicio = hoy - timedelta(days=hoy.weekday())
            fecha_inicio = fecha_inicio.replace(hour=0, minute=0, second=0, microsecond=0)
        elif periodo == 'mes':
            fecha_inicio = hoy.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        else:  # año
            fecha_inicio = hoy.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        
        ventas = maquina.ventas.filter(fecha__gte=fecha_inicio)
        gastos = maquina.gastos.filter(fecha__gte=fecha_inicio.date())
        
        total_ventas = ventas.aggregate(total=Sum('total'))['total'] or 0
        total_ganancias = ventas.aggregate(total=Sum('ganancia'))['total'] or 0
        total_gastos = gastos.aggregate(total=Sum('valor'))['total'] or 0
        utilidad = total_ganancias - total_gastos
        
        # Productos más vendidos
        productos_top = ventas.values(
            'producto__nombre', 'producto__codigo'
        ).annotate(
            cantidad=Sum('cantidad'),
            total=Sum('total')
        ).order_by('-cantidad')[:5]
        
        # Inventario crítico - CORREGIDO
        inventario_critico = maquina.inventarios.annotate(
            porcentaje_calculado=ExpressionWrapper(
                F('stock_actual') * 100.0 / Coalesce(F('stock_maximo'), 1),
                output_field=FloatField()
            )
        ).filter(
            porcentaje_calculado__lt=20,
            stock_maximo__gt=0
        ).values(
            'producto__nombre', 
            'stock_actual', 
            'stock_maximo'
        ).annotate(
            porcentaje_surtido=F('porcentaje_calculado')
        )
        
        return Response({
            'maquina': MaquinaSerializer(maquina).data,
            'periodo': periodo,
            'totales': {
                'ventas': float(total_ventas),
                'ganancias': float(total_ganancias),
                'gastos': float(total_gastos),
                'utilidad': float(utilidad),
            },
            'productos_top': list(productos_top),
            'inventario_critico': list(inventario_critico),
        })
    @action(detail=True, methods=['get'])
    def faltantes(self, request, pk=None):
        """Obtiene productos faltantes de una máquina (para visita)"""
        try:
            maquina = self.get_object()
            inventario = InventarioMaquina.objects.filter(
                maquina=maquina
            ).select_related('producto')
            
            # Calcular faltantes
            productos_faltantes = []
            for item in inventario:
                faltante = item.stock_maximo - item.stock_actual
                if faltante > 0:
                    productos_faltantes.append({
                        'id': item.id,
                        'producto_id': item.producto.id,
                        'producto_nombre': item.producto.nombre,
                        'producto_codigo': item.producto.codigo,
                        'codigo_espiral': item.codigo_espiral,
                        'stock_actual': item.stock_actual,
                        'stock_maximo': item.stock_maximo,
                        'faltante': faltante,
                        'precio_venta': str(item.precio_venta),
                    })
            
            return Response(productos_faltantes)
            
        except Maquina.DoesNotExist:
            return Response(
                {'error': 'Máquina no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )
    @action(detail=False, methods=['get'])
    def top_facturacion(self, request):
        """Ranking de máquinas por facturación"""
        
        # Obtener filtros de fecha
        fecha_inicio = request.query_params.get('fecha_inicio')
        fecha_fin = request.query_params.get('fecha_fin')
        
        queryset = Venta.objects.all()
        
        if fecha_inicio and fecha_fin:
            queryset = queryset.filter(
                fecha__date__gte=fecha_inicio,
                fecha__date__lte=fecha_fin
            )
        
        # Agrupar por máquina
        top_maquinas = queryset.values(
            'maquina__id', 
            'maquina__nombre', 
            'maquina__codigo'
        ).annotate(
            ventas_totales=Coalesce(Sum('total'), Value(0, output_field=DecimalField())),
            ganancias_totales=Coalesce(Sum('ganancia'), Value(0, output_field=DecimalField())),
            unidades_vendidas=Coalesce(Sum('cantidad'), Value(0))
        ).order_by('-ventas_totales')[:10]  # Top 10
        
        # Calcular total general para porcentajes
        total_general = queryset.aggregate(
            total=Coalesce(Sum('total'), Value(0, output_field=DecimalField()))
        )['total']
        
        resultados = []
        for item in top_maquinas:
            porcentaje = 0
            if total_general > 0:
                porcentaje = (float(item['ventas_totales']) / float(total_general)) * 100
            
            resultados.append({
                'id': item['maquina__id'],
                'codigo': item['maquina__codigo'],
                'nombre': item['maquina__nombre'],
                'ventas_totales': float(item['ventas_totales']),
                'ganancias_totales': float(item['ganancias_totales']),
                'unidades_vendidas': item['unidades_vendidas'],
                'porcentaje': round(porcentaje, 2)
            })
        
        return Response({
            'total_general': float(total_general),
            'top_maquinas': resultados,
            'periodo': {
                'fecha_inicio': fecha_inicio,
                'fecha_fin': fecha_fin
            }
        })

class ProductoViewSet(viewsets.ModelViewSet):
    queryset = Producto.objects.filter(estado=True)
    serializer_class = ProductoSerializer
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def categorias(self, request):
        """Obtener todas las categorías"""
        categorias = Producto.objects.values_list('categoria', flat=True).distinct()
        return Response(list(categorias))
    
    @action(detail=True, methods=['get'])
    def maquinas(self, request, pk=None):
        """Máquinas donde está disponible este producto"""
        producto = self.get_object()
        inventarios = producto.inventariomaquina_set.all()
        maquinas = [inv.maquina for inv in inventarios]
        serializer = MaquinaSerializer(maquinas, many=True)
        return Response(serializer.data)

class InventarioMaquinaViewSet(viewsets.ModelViewSet):
    queryset = InventarioMaquina.objects.all()
    serializer_class = InventarioMaquinaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        print("\n🔵 ===== INVENTARIO VIEWSET =====")
        print(f"🔵 Query params: {dict(self.request.query_params)}")
        
        # Empezar con todos los objetos
        queryset = InventarioMaquina.objects.all()
        
        # Filtrar por máquina (USANDO EL NOMBRE CORRECTO DEL CAMPO)
        maquina_id = self.request.query_params.get('maquina_id')
        print(f"🔵 maquina_id recibido: {maquina_id}")
        
        if maquina_id:
            print(f"🔵 Aplicando filtro para máquina_id: {maquina_id}")
            # IMPORTANTE: El campo en la base de datos se llama 'maquina' (no 'maquina_id')
            queryset = queryset.filter(maquina_id=maquina_id)
            
            # Verificar cuántos registros quedaron después del filtro
            print(f"✅ Registros después del filtro: {queryset.count()}")
        
        # Filtrar por producto si viene
        producto_id = self.request.query_params.get('producto_id')
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        # Filtrar por stock crítico
        critico = self.request.query_params.get('critico')
        if critico == 'true':
            queryset = queryset.annotate(
                porcentaje_calculado=ExpressionWrapper(
                    F('stock_actual') * 100.0 / Coalesce(F('stock_maximo'), 1),
                    output_field=FloatField()
                )
            ).filter(
                porcentaje_calculado__lt=20,
                stock_maximo__gt=0
            )
        
        # ORDENAR PARA EVITAR EL WARNING
        queryset = queryset.order_by('id')
        
        print(f"🔵 Total resultados finales: {queryset.count()}")
        return queryset
    
    @action(detail=True, methods=['post'])
    def actualizar_stock(self, request, pk=None):
        """Actualizar stock manualmente (para visitas)"""
        inventario = self.get_object()
        stock_actual = request.data.get('stock_actual')
        
        if stock_actual is None:
            return Response(
                {'error': 'Se requiere stock_actual'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Calcular ventas desde último surtido
        ventas_generadas = inventario.stock_surtido - stock_actual
        if ventas_generadas > 0:
            # Crear ventas automáticas
            Venta.objects.create(
                maquina=inventario.maquina,
                producto=inventario.producto,
                inventario=inventario,
                cantidad=ventas_generadas,
                precio_unitario=inventario.precio_venta,
                total=ventas_generadas * inventario.precio_venta,
                costo=ventas_generadas * inventario.producto.precio_compra,
                ganancia=(ventas_generadas * inventario.precio_venta) - 
                        (ventas_generadas * inventario.producto.precio_compra)
            )
        
        # Actualizar inventario
        inventario.stock_actual = stock_actual
        inventario.stock_surtido = stock_actual
        inventario.save()
        
        serializer = self.get_serializer(inventario)
        return Response(serializer.data)

class VentaViewSet(viewsets.ModelViewSet):
    queryset = Venta.objects.all()
    serializer_class = VentaSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Venta.objects.all()
        user = self.request.user
        
        # Operarios solo ven sus ventas (si están asociadas a visitas)
        if user.rol == 'operario':
            queryset = queryset.filter(
                Q(visita__operario=user) | Q(visita__isnull=True)
            )
        
        # Filtros
        maquina_id = self.request.query_params.get('maquina_id')
        producto_id = self.request.query_params.get('producto_id')
        fecha_inicio = self.request.query_params.get('fecha_inicio')
        fecha_fin = self.request.query_params.get('fecha_fin')
        
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        if fecha_inicio and fecha_fin:
            try:
                fecha_inicio = datetime.strptime(fecha_inicio, '%Y-%m-%d')
                fecha_fin = datetime.strptime(fecha_fin, '%Y-%m-%d')
                fecha_fin = fecha_fin.replace(hour=23, minute=59, second=59)
                queryset = queryset.filter(fecha__range=[fecha_inicio, fecha_fin])
            except ValueError:
                pass
        
        return queryset
    
    def perform_create(self, serializer):
        """Crear venta manual (solo admin)"""
        if self.request.user.rol != 'admin':
            raise PermissionDenied('Solo administradores pueden crear ventas manualmente')
        serializer.save()
    
    @action(detail=False, methods=['get'])
    def reporte(self, request):
        """Reporte avanzado de ventas - CORREGIDO"""
        from django.db.models import DecimalField
        from django.db.models.functions import Coalesce as CoalesceFunc
        from zoneinfo import ZoneInfo
        from datetime import datetime, timedelta
        
        # Obtener fechas directamente de los parámetros
        fecha_inicio_str = request.query_params.get('fecha_inicio')
        fecha_fin_str = request.query_params.get('fecha_fin')
        
        # Si no vienen fechas, usar últimos 30 días
        if not fecha_inicio_str or not fecha_fin_str:
            hoy = timezone.now().date()
            fecha_fin = hoy
            fecha_inicio = hoy - timedelta(days=30)
            fecha_inicio_str = fecha_inicio.isoformat()
            fecha_fin_str = fecha_fin.isoformat()
        else:
            # Parsear fechas
            fecha_inicio = datetime.strptime(fecha_inicio_str, '%Y-%m-%d').date()
            fecha_fin = datetime.strptime(fecha_fin_str, '%Y-%m-%d').date()
        
        # Crear rangos considerando zona horaria
        local_tz = ZoneInfo('America/Bogota')
        
        fecha_inicio_dt = datetime.combine(fecha_inicio, datetime.min.time()).replace(tzinfo=local_tz)
        fecha_fin_dt = datetime.combine(fecha_fin, datetime.max.time()).replace(tzinfo=local_tz)
        
        # Filtrar ventas
        queryset = Venta.objects.filter(
            fecha__range=[fecha_inicio_dt, fecha_fin_dt]
        )
        
        # Filtros adicionales
        maquina_id = request.query_params.get('maquina_id')
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        
        producto_id = request.query_params.get('producto_id')
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        # Cálculos totales - CORREGIDO con output_field
        totales = queryset.aggregate(
            ventas=CoalesceFunc(Sum('total'), Value(0, output_field=DecimalField())),
            ganancias=CoalesceFunc(Sum('ganancia'), Value(0, output_field=DecimalField())),
            unidades=CoalesceFunc(Sum('cantidad'), Value(0)),
            costo=CoalesceFunc(Sum('costo'), Value(0, output_field=DecimalField()))
        )
        
        # Margen
        margen = 0
        if totales['ventas'] > 0:
            margen = (float(totales['ganancias']) / float(totales['ventas'])) * 100
        
        # Ventas por día
        ventas_por_dia = queryset.extra(
            {'fecha_simple': "DATE(fecha)"}
        ).values('fecha_simple').annotate(
            ventas=CoalesceFunc(Sum('total'), Value(0, output_field=DecimalField())),
            ganancias=CoalesceFunc(Sum('ganancia'), Value(0, output_field=DecimalField()))
        ).order_by('fecha_simple')
        
        # Ventas por producto
        ventas_por_producto = queryset.values(
            'producto__codigo', 'producto__nombre'
        ).annotate(
            cantidad=CoalesceFunc(Sum('cantidad'), Value(0)),
            ventas=CoalesceFunc(Sum('total'), Value(0, output_field=DecimalField())),
            ganancia=CoalesceFunc(Sum('ganancia'), Value(0, output_field=DecimalField()))
        ).order_by('-ventas')
        
        # Ventas por máquina
        ventas_por_maquina = queryset.values(
            'maquina__codigo', 'maquina__nombre'
        ).annotate(
            ventas=CoalesceFunc(Sum('total'), Value(0, output_field=DecimalField())),
            ganancia=CoalesceFunc(Sum('ganancia'), Value(0, output_field=DecimalField()))
        ).order_by('-ventas')
        
        # Convertir a listas con valores float
        ventas_por_dia_list = []
        for item in ventas_por_dia:
            ventas_por_dia_list.append({
                'fecha_simple': item['fecha_simple'],
                'ventas': float(item['ventas']),
                'ganancias': float(item['ganancias'])
            })
        
        ventas_por_producto_list = []
        for item in ventas_por_producto:
            ventas_por_producto_list.append({
                'producto__codigo': item['producto__codigo'],
                'producto__nombre': item['producto__nombre'],
                'cantidad': item['cantidad'],
                'ventas': float(item['ventas']),
                'ganancia': float(item['ganancia'])
            })
        
        ventas_por_maquina_list = []
        for item in ventas_por_maquina:
            ventas_por_maquina_list.append({
                'maquina__codigo': item['maquina__codigo'],
                'maquina__nombre': item['maquina__nombre'],
                'ventas': float(item['ventas']),
                'ganancia': float(item['ganancia'])
            })
        
        # Construir respuesta
        data = {
            'periodo': {
                'fecha_inicio': fecha_inicio_str,
                'fecha_fin': fecha_fin_str,
            },
            'totales': {
                'ventas': float(totales['ventas']),
                'ganancias': float(totales['ganancias']),
                'unidades': totales['unidades'],
                'costo': float(totales['costo']),
                'margen': margen,
            },
            'ventas_por_dia': ventas_por_dia_list,
            'ventas_por_producto': ventas_por_producto_list,
            'ventas_por_maquina': ventas_por_maquina_list,
        }
        
        return Response(data)

    @action(detail=False, methods=['get'])
    def estadisticas(self, request):
        """Estadísticas generales"""
        # Hoy
        hoy = timezone.now().date()
        ventas_hoy = Venta.objects.filter(fecha__date=hoy)
        
        # Este mes
        mes_actual = hoy.replace(day=1)
        ventas_mes = Venta.objects.filter(fecha__date__gte=mes_actual)
        
        # Producto más vendido hoy
        producto_top_hoy = ventas_hoy.values(
            'producto__nombre'
        ).annotate(
            cantidad=Sum('cantidad')
        ).order_by('-cantidad').first()
        
        # Máquina con más ventas hoy
        maquina_top_hoy = ventas_hoy.values(
            'maquina__nombre'
        ).annotate(
            ventas=Sum('total')
        ).order_by('-ventas').first()
        
        return Response({
            'hoy': {
                'ventas': float(ventas_hoy.aggregate(total=Sum('total'))['total'] or 0),
                'ganancias': float(ventas_hoy.aggregate(total=Sum('ganancia'))['total'] or 0),
                'unidades': ventas_hoy.aggregate(total=Sum('cantidad'))['total'] or 0,
                'producto_top': producto_top_hoy,
                'maquina_top': maquina_top_hoy,
            },
            'mes_actual': {
                'ventas': float(ventas_mes.aggregate(total=Sum('total'))['total'] or 0),
                'ganancias': float(ventas_mes.aggregate(total=Sum('ganancia'))['total'] or 0),
            }
        })

class GastoViewSet(viewsets.ModelViewSet):
    queryset = Gasto.objects.all()
    serializer_class = GastoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Gasto.objects.all()
        
        if user.rol == 'operario':
            queryset = queryset.filter(usuario=user)
        
        # Filtros por fecha - VERSIÓN SIMPLIFICADA
        fecha_inicio = self.request.query_params.get('fecha_inicio')
        fecha_fin = self.request.query_params.get('fecha_fin')
        
        if fecha_inicio:
            from django.utils.dateparse import parse_date
            import datetime
            
            fecha_inicio_parsed = parse_date(fecha_inicio)
            if fecha_inicio_parsed:
                fecha_inicio_datetime = datetime.datetime.combine(
                    fecha_inicio_parsed, 
                    datetime.time.min
                )
                queryset = queryset.filter(fecha__gte=fecha_inicio_datetime)
        
        if fecha_fin:
            from django.utils.dateparse import parse_date
            import datetime
            
            fecha_fin_parsed = parse_date(fecha_fin)
            if fecha_fin_parsed:
                fecha_fin_datetime = datetime.datetime.combine(
                    fecha_fin_parsed, 
                    datetime.time.max
                )
                queryset = queryset.filter(fecha__lte=fecha_fin_datetime)
        
        return queryset.order_by('-fecha')
    
    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)
    
    @action(detail=False, methods=['get'])
    def resumen(self, request):
        """Resumen de gastos agrupados por categoría"""
        
        # Obtener filtros de fecha
        fecha_inicio = request.query_params.get('fecha_inicio')
        fecha_fin = request.query_params.get('fecha_fin')
        
        queryset = Gasto.objects.all()
        
        if fecha_inicio and fecha_fin:
            queryset = queryset.filter(
                fecha__gte=fecha_inicio,
                fecha__lte=fecha_fin
            )
        
        # Agrupar por categoría
        from django.db.models import Sum, Value, DecimalField
        from django.db.models.functions import Coalesce
        
        resumen_por_categoria = queryset.values('tipo').annotate(
            total=Coalesce(Sum('valor'), Value(0, output_field=DecimalField()))
        ).order_by('-total')
        
        # Calcular total general
        total_general = queryset.aggregate(
            total=Coalesce(Sum('valor'), Value(0, output_field=DecimalField()))
        )['total']
        
        # Formatear respuesta
        categorias = []
        for item in resumen_por_categoria:
            categoria_nombre = self._get_categoria_nombre(item['tipo'])
            porcentaje = 0
            if total_general > 0:
                porcentaje = (float(item['total']) / float(total_general)) * 100
            
            categorias.append({
                'categoria': item['tipo'],
                'categoria_nombre': categoria_nombre,
                'total': float(item['total']),
                'porcentaje': round(porcentaje, 2),
                'icono': self._get_categoria_icono(item['tipo']),
                'color': self._get_categoria_color(item['tipo'])
            })
        
        return Response({
            'total_general': float(total_general),
            'categorias': categorias,
            'periodo': {
                'fecha_inicio': fecha_inicio,
                'fecha_fin': fecha_fin
            }
        })
    
    def _get_categoria_nombre(self, tipo):
        """Retorna nombre amigable para cada categoría"""
        nombres = {
            'transporte': 'Transporte',
            'mantenimiento': 'Mantenimiento',
            'reposicion': 'Reposición',
            'servicios': 'Servicios',
            'otros': 'Otros',
        }
        return nombres.get(tipo, tipo.capitalize())
    
    def _get_categoria_icono(self, tipo):
        """Retorna ícono para cada categoría"""
        iconos = {
            'transporte': 'local_shipping',
            'mantenimiento': 'build',
            'reposicion': 'inventory',
            'servicios': 'miscellaneous_services',
            'otros': 'more_horiz',
        }
        return iconos.get(tipo, 'category')
    
    def _get_categoria_color(self, tipo):
        """Retorna color para cada categoría"""
        colores = {
            'transporte': '#F59E0B',
            'mantenimiento': '#EF4444',
            'reposicion': '#10B981',
            'servicios': '#3B82F6',
            'otros': '#6B7280',
        }
        return colores.get(tipo, '#6B7280')

class VisitaViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar visitas de operarios
    """
    queryset = Visita.objects.all()
    serializer_class = VisitaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Filtra visitas según el rol del usuario
        """
        user = self.request.user
        if user.rol == 'operario':
            return Visita.objects.filter(operario=user).order_by('-fecha_inicio')
        return Visita.objects.all().order_by('-fecha_inicio')

    @action(detail=False, methods=['get'])
    def mis_visitas(self, request):
        """
        Endpoint: GET /api/visitas/mis_visitas/
        Devuelve solo las visitas del operario actual
        """
        try:
            visitas = self.get_queryset().filter(operario=request.user)
            serializer = self.get_serializer(visitas, many=True)
            return Response({
                'count': visitas.count(),
                'results': serializer.data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def resumen(self, request):
        """
        Endpoint: GET /api/visitas/resumen/
        Devuelve estadísticas de visitas del operario
        """
        try:
            user = request.user
            visitas = Visita.objects.filter(operario=user)
            
            total_visitas = visitas.count()
            completadas = visitas.filter(estado='completada').count()
            en_curso = visitas.filter(estado='en_curso').count()
            canceladas = visitas.filter(estado='cancelada').count()
            
            # Última visita
            ultima = visitas.filter(estado='completada').order_by('-fecha_fin').first()
            
            return Response({
                'total_visitas': total_visitas,
                'completadas': completadas,
                'en_curso': en_curso,
                'canceladas': canceladas,
                'ultima_visita': {
                    'fecha': ultima.fecha_fin.isoformat() if ultima and ultima.fecha_fin else None,
                    'maquina': ultima.maquina.nombre if ultima else None
                } if ultima else None
            })
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def iniciar(self, request):
        """
        Endpoint: POST /api/visitas/iniciar/
        Inicia una nueva visita para una máquina
        """
        maquina_id = request.data.get('maquina_id')
        
        if not maquina_id:
            return Response(
                {'error': 'Se requiere maquina_id'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            maquina = Maquina.objects.get(id=maquina_id)
            
            # Verificar que la máquina esté activa
            if maquina.estado not in ['activa', 'activo']:
                return Response(
                    {'error': 'La máquina no está activa'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Verificar que no haya una visita activa
            visita_activa = Visita.objects.filter(
                maquina=maquina,
                estado='en_curso'
            ).first()
            
            if visita_activa:
                return Response({
                    'error': 'Ya hay una visita en curso',
                    'visita_id': visita_activa.id
                }, status=status.HTTP_400_BAD_REQUEST)
            
            from django.utils import timezone
            
            # Crear nueva visita
            visita = Visita.objects.create(
                maquina=maquina,
                operario=request.user,
                fecha_inicio=timezone.now(),
                fecha_programada=timezone.now().date(),
                estado='en_curso'
            )
            
            # Obtener productos faltantes
            inventario = InventarioMaquina.objects.filter(
                maquina=maquina
            ).select_related('producto')
            
            productos_faltantes = []
            for item in inventario:
                faltante = item.stock_maximo - item.stock_actual
                if faltante > 0:
                    productos_faltantes.append({
                        'inventario_id': item.id,
                        'producto_id': item.producto.id,
                        'producto_nombre': item.producto.nombre,
                        'producto_codigo': item.producto.codigo,
                        'codigo_espiral': item.codigo_espiral,
                        'stock_actual': item.stock_actual,
                        'stock_maximo': item.stock_maximo,
                        'faltante': faltante,
                        'precio_venta': str(item.precio_venta)
                    })
            
            # Construir respuesta manualmente para evitar errores de serialización
            response_data = {
                'id': visita.id,
                'maquina': visita.maquina.id,
                'maquina_nombre': visita.maquina.nombre,
                'operario': visita.operario.id,
                'operario_nombre': visita.operario.username,
                'fecha_inicio': visita.fecha_inicio.isoformat() if visita.fecha_inicio else None,
                'fecha_programada': visita.fecha_programada.isoformat() if visita.fecha_programada else None,
                'estado': visita.estado,
                'productos_faltantes': productos_faltantes
            }
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
        except Maquina.DoesNotExist:
            return Response(
                {'error': 'Máquina no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            import traceback
            print(f"Error en iniciar visita: {str(e)}")
            print(traceback.format_exc())
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def finalizar(self, request, pk=None):
        """
        Endpoint: POST /api/visitas/{id}/finalizar/
        Finaliza una visita y registra las recargas
        """
        try:
            visita = self.get_object()
            
            # Verificar que la visita esté en curso
            if visita.estado != 'en_curso':
                return Response(
                    {'error': f'Esta visita no está en curso (estado: {visita.estado})'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Verificar que el operario sea el mismo
            if visita.operario != request.user:
                return Response(
                    {'error': 'No tienes permiso para finalizar esta visita'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            productos_surtidos = request.data.get('productos_surtidos', [])
            
            # Validar que productos_surtidos sea una lista
            if not isinstance(productos_surtidos, list):
                return Response(
                    {'error': 'productos_surtidos debe ser una lista'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Registrar recargas para los productos surtidos
            recargas_creadas = []
            errores = []
            
            for inventario_id in productos_surtidos:
                try:
                    inventario = InventarioMaquina.objects.select_related('producto').get(
                        id=inventario_id,
                        maquina=visita.maquina
                    )
                    
                    # Calcular cantidad faltante
                    cantidad_faltante = inventario.stock_maximo - inventario.stock_actual
                    
                    if cantidad_faltante > 0:
                        # Crear recarga
                        recarga = Recarga.objects.create(
                            maquina=visita.maquina,
                            producto=inventario.producto,
                            inventario=inventario,
                            visita=visita,
                            cantidad=cantidad_faltante,
                            origen='manual'
                        )
                        recargas_creadas.append({
                            'id': recarga.id,
                            'producto': inventario.producto.nombre,
                            'cantidad': cantidad_faltante
                        })
                        
                        # Actualizar stock
                        inventario.stock_actual = inventario.stock_maximo
                        inventario.save()
                        
                except InventarioMaquina.DoesNotExist:
                    errores.append(f"Inventario {inventario_id} no encontrado")
                except Exception as e:
                    errores.append(f"Error con inventario {inventario_id}: {str(e)}")
            
            # Finalizar visita
            visita.estado = 'completada'
            visita.fecha_fin = timezone.now()
            visita.save()
            
            return Response({
                'status': 'ok',
                'visita_id': visita.id,
                'recargas_creadas': recargas_creadas,
                'total_recargas': len(recargas_creadas),
                'errores': errores if errores else None
            }, status=status.HTTP_200_OK)
            
        except Visita.DoesNotExist:
            return Response(
                {'error': 'Visita no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            import traceback
            print(f"Error en finalizar visita: {str(e)}")
            print(traceback.format_exc())
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def cancelar(self, request, pk=None):
        """
        Endpoint: POST /api/visitas/{id}/cancelar/
        Cancela una visita en curso
        """
        try:
            visita = self.get_object()
            
            # Verificar permisos
            if visita.operario != request.user and request.user.rol != 'admin':
                return Response(
                    {'error': 'No tienes permiso para cancelar esta visita'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Verificar que la visita esté en curso
            if visita.estado != 'en_curso':
                return Response({
                    'error': f'No se puede cancelar una visita en estado: {visita.estado}',
                    'visita_id': visita.id,
                    'estado_actual': visita.estado
                }, status=status.HTTP_400_BAD_REQUEST)
            
            motivo = request.data.get('motivo', 'Cancelada por el operario')
            
            # Cambiar estado a cancelada
            visita.estado = 'cancelada'
            visita.fecha_fin = timezone.now()
            visita.save()
            
            return Response({
                'status': 'ok',
                'visita_id': visita.id,
                'estado': visita.estado,
                'motivo': motivo
            }, status=status.HTTP_200_OK)
            
        except Visita.DoesNotExist:
            return Response(
                {'error': 'Visita no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def create(self, request, *args, **kwargs):
        """
        Redirigir POST /api/visitas/ a iniciar
        """
        return self.iniciar(request)

    def update(self, request, *args, **kwargs):
        """
        No permitir actualizaciones directas
        """
        return Response(
            {'error': 'Use finalizar o cancelar para modificar visitas'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

    def partial_update(self, request, *args, **kwargs):
        """
        No permitir actualizaciones parciales
        """
        return Response(
            {'error': 'No se permiten actualizaciones parciales'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

    def destroy(self, request, *args, **kwargs):
        """
        No permitir eliminar visitas
        """
        return Response(
            {'error': 'Las visitas no se pueden eliminar, solo cancelar'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

class ConteoViewSet(viewsets.ModelViewSet):
    queryset = Conteo.objects.all()
    serializer_class = ConteoSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Conteo.objects.all()
        
        # Filtros
        maquina_id = self.request.query_params.get('maquina_id')
        tipo = self.request.query_params.get('tipo')
        fecha = self.request.query_params.get('fecha')
        
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if tipo:
            queryset = queryset.filter(tipo=tipo)
        if fecha:
            try:
                fecha_obj = datetime.strptime(fecha, '%Y-%m-%d').date()
                queryset = queryset.filter(fecha_hora__date=fecha_obj)
            except ValueError:
                pass
        
        return queryset
    
    @action(detail=True, methods=['get'])
    def detalles(self, request, pk=None):
        """Detalles de un conteo"""
        conteo = self.get_object()
        detalles = conteo.detalles.all()
        serializer = ConteoDetalleSerializer(detalles, many=True)
        return Response(serializer.data)

class CierreMensualViewSet(viewsets.ModelViewSet):
    queryset = CierreMensual.objects.all()
    serializer_class = CierreMensualSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(responsable=self.request.user)
    
    @action(detail=True, methods=['post'])
    def calcular(self, request, pk=None):
        """Calcular automáticamente los totales del cierre"""
        cierre = self.get_object()
        
        # Calcular ventas del mes
        ventas = Venta.objects.filter(
            maquina=cierre.maquina,
            fecha__year=cierre.año,
            fecha__month=cierre.mes
        )
        
        # Calcular gastos del mes
        gastos = Gasto.objects.filter(
            maquina=cierre.maquina,
            fecha__year=cierre.año,
            fecha__month=cierre.mes
        )
        
        total_ventas = ventas.aggregate(total=Sum('total'))['total'] or 0
        total_ganancias = ventas.aggregate(total=Sum('ganancia'))['total'] or 0
        total_gastos = gastos.aggregate(total=Sum('valor'))['total'] or 0
        
        cierre.ventas_totales = total_ventas
        cierre.gastos_totales = total_gastos
        cierre.ganancia_neta = total_ganancias - total_gastos
        cierre.fecha_cierre = timezone.now()
        cierre.save()
        
        serializer = self.get_serializer(cierre)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def evolucion(self, request):
        """Evolución de ventas vs gastos últimos 12 meses"""
        from datetime import date
        from dateutil.relativedelta import relativedelta
        from django.db.models import Sum, Value, DecimalField
        from django.db.models.functions import Coalesce
        
        hoy = date.today()
        resultados = []
        
        # Últimos 12 meses
        for i in range(11, -1, -1):
            fecha_mes = hoy - relativedelta(months=i)
            
            # Buscar cierres del mes
            cierres = CierreMensual.objects.filter(
                año=fecha_mes.year,  # CORREGIDO: 'año' con ñ, no 'anio'
                mes=fecha_mes.month
            )
            
            ventas = cierres.aggregate(
                total=Coalesce(Sum('ventas_totales'), Value(0, output_field=DecimalField()))
            )['total']
            
            gastos = cierres.aggregate(
                total=Coalesce(Sum('gastos_totales'), Value(0, output_field=DecimalField()))
            )['total']
            
            # Si no hay cierres, calcular de ventas reales
            if ventas == 0:
                ventas_reales = Venta.objects.filter(
                    fecha__year=fecha_mes.year,
                    fecha__month=fecha_mes.month
                ).aggregate(
                    total=Coalesce(Sum('total'), Value(0, output_field=DecimalField()))
                )['total']
                ventas = ventas_reales
            
            if gastos == 0:
                gastos_reales = Gasto.objects.filter(
                    fecha__year=fecha_mes.year,
                    fecha__month=fecha_mes.month
                ).aggregate(
                    total=Coalesce(Sum('valor'), Value(0, output_field=DecimalField()))
                )['total']
                gastos = gastos_reales
            
            utilidad = ventas - gastos
            margen = 0
            if ventas > 0:
                margen = (utilidad / ventas) * 100
            
            resultados.append({
                'mes': fecha_mes.strftime('%b %Y'),
                'fecha': fecha_mes.strftime('%Y-%m'),
                'ventas': float(ventas),
                'gastos': float(gastos),
                'utilidad': float(utilidad),
                'margen': round(margen, 2)
            })
        
        return Response(resultados)
# ==================== REPORTES ESPECIALES ====================
class DashboardView(APIView):
    """Vista para dashboard administrativo"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Solo admin puede ver dashboard completo
        if request.user.rol != 'admin':
            return Response(
                {'error': 'Solo administradores pueden acceder al dashboard'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Obtener filtros de fecha - ACEPTAR AMBOS FORMATOS
        start_date = request.query_params.get('start_date') or request.query_params.get('fecha_inicio')
        end_date = request.query_params.get('end_date') or request.query_params.get('fecha_fin')
        
        hoy = timezone.now().date()
        
        # Filtrar ventas por fecha
        ventas_queryset = Venta.objects.all()
        if start_date and end_date:
            ventas_queryset = ventas_queryset.filter(
                fecha__date__gte=start_date,
                fecha__date__lte=end_date
            )
        
        # Totales del período
        total_ventas_sum = ventas_queryset.aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia'),
            cantidad=Sum('cantidad')
        )
        
        total_ventas = {
            'total': float(total_ventas_sum['total'] or 0),
            'ganancia': float(total_ventas_sum['ganancia'] or 0),
            'cantidad': total_ventas_sum['cantidad'] or 0
        }
        
        # Máquinas activas (usando estado='activo')
        maquinas_activas = Maquina.objects.filter(estado='activo').count()
        total_maquinas = Maquina.objects.count()
        
        # Stock crítico: máquinas activas con porcentaje < 30%
        maquinas_criticas = 0
        maquinas_activas_list = Maquina.objects.filter(estado='activo')
        
        for maquina in maquinas_activas_list:
            try:
                # Obtener inventarios de esta máquina
                inventarios = InventarioMaquina.objects.filter(
                    maquina=maquina,
                    producto__isnull=False
                )
                
                if inventarios.exists():
                    total_capacidad = 0
                    total_actual = 0
                    
                    for inv in inventarios:
                        total_capacidad += inv.capacidad_maxima or 0
                        total_actual += inv.cantidad_actual or 0
                    
                    if total_capacidad > 0:
                        porcentaje = (total_actual / total_capacidad) * 100
                        if porcentaje < 30:
                            maquinas_criticas += 1
                else:
                    # Si no tiene inventario, considerar crítico
                    maquinas_criticas += 1
            except Exception as e:
                print(f"Error calculando stock para {maquina.nombre}: {e}")
                continue
        
        # Ventas por día
        ventas_por_dia = ventas_queryset.values('fecha__date').annotate(
            total=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('fecha__date')
        
        # Top productos
        top_productos = ventas_queryset.values('producto__nombre').annotate(
            cantidad=Sum('cantidad'),
            ventas=Sum('total')
        ).order_by('-ventas')[:5]
        
        # Ventas por máquina
        ventas_por_maquina = ventas_queryset.values('maquina__nombre').annotate(
            ventas=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('-ventas')[:5]
        
        # Ventas hoy
        ventas_hoy_sum = Venta.objects.filter(fecha__date=hoy).aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia'),
            cantidad=Sum('cantidad')
        )
        
        ventas_hoy = {
            'total': float(ventas_hoy_sum['total'] or 0),
            'ganancia': float(ventas_hoy_sum['ganancia'] or 0),
            'cantidad': ventas_hoy_sum['cantidad'] or 0
        }
        
        # Ventas del mes
        mes_actual = hoy.replace(day=1)
        ventas_mes_sum = Venta.objects.filter(fecha__date__gte=mes_actual).aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia')
        )
        
        ventas_mes = {
            'total': float(ventas_mes_sum['total'] or 0),
            'ganancia': float(ventas_mes_sum['ganancia'] or 0)
        }
        
        # Gastos del mes
        gastos_mes_sum = Gasto.objects.filter(
            fecha__gte=mes_actual,
            fecha__lte=hoy
        ).aggregate(total=Sum('valor'))
        
        gastos_mes = float(gastos_mes_sum['total'] or 0)
        
        # Construir respuesta
        data = {
            'ventas_totales': total_ventas['total'],
            'ganancia_total': total_ventas['ganancia'],
            'unidades_vendidas': total_ventas['cantidad'],
            'maquinas_activas': maquinas_activas,
            'stock_critico': maquinas_criticas,
            'total_maquinas': total_maquinas,
            'ventas_por_dia': [
                {
                    'fecha': item['fecha__date'].isoformat() if item['fecha__date'] else '',
                    'total': float(item['total']),
                    'ganancia': float(item['ganancia'])
                }
                for item in ventas_por_dia
            ],
            'top_productos': [
                {
                    'nombre': item['producto__nombre'],
                    'cantidad': item['cantidad'],
                    'ventas': float(item['ventas'])
                }
                for item in top_productos
            ],
            'ventas_por_maquina': [
                {
                    'nombre': item['maquina__nombre'],
                    'ventas': float(item['ventas']),
                    'ganancia': float(item['ganancia'])
                }
                for item in ventas_por_maquina
            ],
            'resumen_hoy': {
                'ventas': ventas_hoy['total'],
                'ganancia': ventas_hoy['ganancia'],
                'cantidad': ventas_hoy['cantidad']
            },
            'resumen_mes': {
                'ventas': ventas_mes['total'],
                'ganancia': ventas_mes['ganancia'],
                'gastos': gastos_mes,
                'utilidad': ventas_mes['total'] - gastos_mes
            }
        }
        
        return Response(data)

class ReporteGeneralView(APIView):
    """Reporte general personalizable"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Solo admin puede ver reportes generales
        if request.user.rol != 'admin':
            return Response(
                {'error': 'Solo administradores pueden acceder a reportes generales'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = ReporteGananciasSerializer(data=request.query_params)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        
        data = serializer.validated_data
        periodo = data['periodo']
        maquina_id = data.get('maquina_id')
        
        # Definir rango según periodo
        hoy = timezone.now()
        if periodo == 'dia':
            fecha_inicio = hoy.replace(hour=0, minute=0, second=0, microsecond=0)
        elif periodo == 'semana':
            fecha_inicio = hoy - timedelta(days=hoy.weekday())
            fecha_inicio = fecha_inicio.replace(hour=0, minute=0, second=0, microsecond=0)
        elif periodo == 'mes':
            fecha_inicio = hoy.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        else:  # año
            fecha_inicio = hoy.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Filtrar ventas
        ventas = Venta.objects.filter(fecha__gte=fecha_inicio)
        if maquina_id:
            ventas = ventas.filter(maquina_id=maquina_id)
        
        # Filtrar gastos
        gastos = Gasto.objects.filter(fecha__gte=fecha_inicio.date())
        if maquina_id:
            gastos = gastos.filter(maquina_id=maquina_id)
        
        # Calcular métricas
        total_ventas = ventas.aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia'),
            cantidad=Sum('cantidad'),
            costo=Sum('costo')
        )
        
        total_gastos = gastos.aggregate(total=Sum('valor'))['total'] or 0
        
        # Ventas por día
        ventas_por_dia = ventas.extra(
            select={'dia': 'DATE(fecha)'}
        ).values('dia').annotate(
            ventas=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('dia')
        
        # Gastos por tipo
        gastos_por_tipo = gastos.values('tipo').annotate(
            total=Sum('valor')
        ).order_by('-total')
        
        return Response({
            'periodo': periodo,
            'fecha_inicio': fecha_inicio,
            'fecha_fin': hoy,
            'filtro_maquina': maquina_id,
            'ventas': {
                'total': float(total_ventas['total'] or 0),
                'ganancia': float(total_ventas['ganancia'] or 0),
                'cantidad': total_ventas['cantidad'] or 0,
                'costo': float(total_ventas['costo'] or 0),
                'margen': float(total_ventas['ganancia'] or 0) / float(total_ventas['total'] or 1) * 100
                if total_ventas['total'] else 0,
            },
            'gastos': {
                'total': float(total_gastos),
                'por_tipo': list(gastos_por_tipo),
            },
            'utilidad': float((total_ventas['ganancia'] or 0) - total_gastos),
            'ventas_por_dia': list(ventas_por_dia),
        })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_recibir_conteos_real(request):
    """Versión real basada en prueba_final"""
    print(f"DEBUG: test_recibir_conteos_real called with method: {request.method}")
    
    # Por ahora, solo prueba que funciona
    return Response({
        "mensaje": "Endpoint de conteos funcionando",
        "usuario": request.user.username,
        "metodo": request.method,
        "data": request.data
    })
class Esp32EstadoDetailView(generics.RetrieveAPIView):
    """GET /api/maquinas/{id}/esp32-estado/"""
    queryset = Esp32Estado.objects.all()
    serializer_class = Esp32EstadoSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        maquina_id = self.kwargs['pk']
        estado, _ = Esp32Estado.objects.get_or_create(maquina_id=maquina_id)
        return estado


class ForzarConteoView(APIView):
    """POST /api/maquinas/{id}/forzar-conteo/"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            maquina = Maquina.objects.get(pk=pk)
        except Maquina.DoesNotExist:
            return Response({'error': 'Máquina no encontrada'}, 
                          status=status.HTTP_404_NOT_FOUND)

        estado, _ = Esp32Estado.objects.get_or_create(maquina=maquina)
        
        # Guardar comando en alertas para que la ESP32 lo recoja
        alertas = estado.alertas or {}
        alertas['forzar_conteo'] = True
        alertas['timestamp'] = timezone.now().isoformat()
        estado.alertas = alertas
        estado.save()

        return Response({
            'status': 'ok',
            'mensaje': 'Comando de forzado registrado. Se ejecutará en el próximo ciclo.'
        })

# ==================== RECARGAS ====================
class RecargaViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar recargas
    """
    queryset = Recarga.objects.all()
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return RecargaCreateSerializer
        return RecargaSerializer
    
    def get_queryset(self):
        user = self.request.user
        queryset = Recarga.objects.all()
        
        # Filtros por query params
        maquina_id = self.request.query_params.get('maquina')
        producto_id = self.request.query_params.get('producto')
        fecha_desde = self.request.query_params.get('fecha_desde')
        fecha_hasta = self.request.query_params.get('fecha_hasta')
        origen = self.request.query_params.get('origen')
        
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        if fecha_desde:
            queryset = queryset.filter(fecha__gte=fecha_desde)
        if fecha_hasta:
            queryset = queryset.filter(fecha__lte=fecha_hasta)
        if origen:
            queryset = queryset.filter(origen=origen)
            
        # Operario solo ve sus recargas
        if user.rol == 'operario':
            queryset = queryset.filter(responsable=user)
            return Recarga.objects.filter(visita__operario=user)
        return Recarga.objects.all()
        return queryset
    
    @action(detail=False, methods=['get'])
    def resumen(self, request):
        """Resumen de recargas por período"""
        from django.db.models import Sum
        
        hoy = timezone.now()
        primer_dia_mes = hoy.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        recargas = self.get_queryset()
        
        # Recargas del mes
        recargas_mes = recargas.filter(fecha__gte=primer_dia_mes)
        total_mes = recargas_mes.aggregate(
            total=Sum('cantidad'),
            recargas=Count('id')
        )
        
        # Top productos recargados
        top_productos = recargas_mes.values(
            'producto__id', 'producto__nombre'
        ).annotate(
            total=Sum('cantidad')
        ).order_by('-total')[:5]
        
        return Response({
            'total_mes': total_mes,
            'top_productos': top_productos,
        })

class ConfigEsp32View(APIView):
    """PUT /api/maquinas/{id}/config-esp32/"""
    permission_classes = [IsAuthenticated]

    def put(self, request, pk):
        try:
            maquina = Maquina.objects.get(pk=pk)
        except Maquina.DoesNotExist:
            return Response({'error': 'Máquina no encontrada'}, 
                          status=status.HTTP_404_NOT_FOUND)

        intervalo = request.data.get('intervalo_segundos')
        if not intervalo or not isinstance(intervalo, int) or intervalo < 300 or intervalo > 3600:
            return Response({
                'error': 'intervalo_segundos debe ser un número entre 300 y 3600'
            }, status=status.HTTP_400_BAD_REQUEST)

        estado, _ = Esp32Estado.objects.get_or_create(maquina=maquina)
        estado.intervalo_actual = intervalo
        estado.save()

        return Response({
            'status': 'ok',
            'nuevo_intervalo': intervalo
        })
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_esp32_endpoint(request):
    """Vista de prueba para verificar que POST funciona"""
    return Response({
        "mensaje": "Vista de prueba funcionando",
        "usuario": request.user.username,
        "metodo": request.method
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def test_recibir_conteo(request):
    """Versión simplificada para probar"""
    return Response({
        "mensaje": "Endpoint de prueba para recibir conteos funcionando",
        "usuario": request.user.username,
        "data": request.data
    })
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def prueba_final(request):
    """Endpoint de prueba definitivo"""
    return Response({
        "mensaje": "¡Funciona!",
        "usuario": request.user.username,
        "metodo": request.method
    })
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def endpoint_que_si_funciona(request):
    """
    Endpoint definitivo para recibir lecturas de ESP32
    """
    print(f"DEBUG: endpoint_que_si_funciona called")
    
    # El usuario viene del JWT
    usuario = request.user
    
    try:
        codigo_maquina = usuario.username.replace('esp32_', '').upper()
        maquina = Maquina.objects.get(codigo=codigo_maquina)
    except Maquina.DoesNotExist:
        return Response(
            {"error": "Usuario no asociado a ninguna máquina"},
            status=status.HTTP_403_FORBIDDEN
        )
    
    timestamp_recepcion = timezone.now()
    serializer = RecibirConteoSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data

    if 'maquina_codigo' in data and data['maquina_codigo'] != maquina.codigo:
        return Response(
            {"error": "El código de máquina en el body no coincide"},
            status=status.HTTP_403_FORBIDDEN
        )

    estado_esp_data = data.get('estado_esp', {})
    esp32_estado, _ = Esp32Estado.objects.get_or_create(maquina=maquina)
    
    esp32_estado.ultima_conexion = timestamp_recepcion
    esp32_estado.estado = estado_esp_data.get('estado', 'online')
    esp32_estado.memoria_ocupada = estado_esp_data.get('memoria_ocupada', 0)
    esp32_estado.firmware_version = estado_esp_data.get('firmware', esp32_estado.firmware_version)
    esp32_estado.batch_pendientes = estado_esp_data.get('batches_pendientes', 0)
    esp32_estado.save()

    batch_id = data.get('batch_id', f"batch_{timestamp_recepcion.timestamp()}")
    resultados = procesar_lecturas_esp32(
        maquina=maquina,
        batch_id=batch_id,
        lecturas_raw=data['lecturas'],
        timestamp_recepcion=timestamp_recepcion
    )

    response_data = {
        'status': 'ok',
        'intervalo_segundos': esp32_estado.intervalo_actual,
        'comandos': [],
        'procesado': {
            'ventas': resultados['ventas_creadas'],
            'recargas': resultados['recargas_creadas'],
            'errores': resultados['errores']
        }
    }

    return Response(response_data, status=status.HTTP_200_OK)
