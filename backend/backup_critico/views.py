from rest_framework import viewsets, status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Sum, Count, Avg, Q, F, ExpressionWrapper, FloatField
from django.db.models.functions import Coalesce
from django.utils import timezone
from datetime import datetime, timedelta
import json
from .models import *
from .serializers import *
from .permissions import *

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
    serializer_class = InventarioMaquinaSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = InventarioMaquina.objects.all()
        
        # Filtros
        maquina_id = self.request.query_params.get('maquina_id')
        producto_id = self.request.query_params.get('producto_id')
        critico = self.request.query_params.get('critico')
        
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        if critico == 'true':
            # CORREGIDO: Calcular porcentaje dinámicamente
            queryset = queryset.annotate(
                porcentaje_calculado=ExpressionWrapper(
                    F('stock_actual') * 100.0 / Coalesce(F('stock_maximo'), 1),
                    output_field=FloatField()
                )
            ).filter(
                porcentaje_calculado__lt=20,
                stock_maximo__gt=0
            )
        
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
        """Reporte avanzado de ventas"""
        serializer = ReporteVentasSerializer(data=request.query_params)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        queryset = Venta.objects.filter(
            fecha__range=[data['fecha_inicio'], data['fecha_fin']]
        )
        
        if 'maquina_id' in data:
            queryset = queryset.filter(maquina_id=data['maquina_id'])
        if 'producto_id' in data:
            queryset = queryset.filter(producto_id=data['producto_id'])
        
        # Cálculos
        totales = queryset.aggregate(
            ventas=Sum('total'),
            ganancias=Sum('ganancia'),
            unidades=Sum('cantidad'),
            costo=Sum('costo')
        )
        
        # Por día
        ventas_por_dia = queryset.extra(
            {'fecha_simple': "DATE(fecha)"}
        ).values('fecha_simple').annotate(
            ventas=Sum('total'),
            ganancias=Sum('ganancia')
        ).order_by('fecha_simple')
        
        # Por producto
        ventas_por_producto = queryset.values(
            'producto__codigo', 'producto__nombre'
        ).annotate(
            cantidad=Sum('cantidad'),
            ventas=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('-ventas')
        
        # Por máquina
        ventas_por_maquina = queryset.values(
            'maquina__codigo', 'maquina__nombre'
        ).annotate(
            ventas=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('-ventas')
        
        return Response({
            'periodo': {
                'fecha_inicio': data['fecha_inicio'],
                'fecha_fin': data['fecha_fin'],
            },
            'totales': {
                'ventas': float(totales['ventas'] or 0),
                'ganancias': float(totales['ganancias'] or 0),
                'unidades': totales['unidades'] or 0,
                'costo': float(totales['costo'] or 0),
                'margen': float(totales['ganancias'] or 0) / float(totales['ventas'] or 1) * 100
                if totales['ventas'] else 0,
            },
            'ventas_por_dia': list(ventas_por_dia),
            'ventas_por_producto': list(ventas_por_producto),
            'ventas_por_maquina': list(ventas_por_maquina),
        })
    
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
    serializer_class = GastoSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Gasto.objects.all()
        user = self.request.user
        
        # Operarios solo ven sus gastos
        if user.rol == 'operario':
            queryset = queryset.filter(usuario=user)
        
        # Filtros
        tipo = self.request.query_params.get('tipo')
        maquina_id = self.request.query_params.get('maquina_id')
        fecha_inicio = self.request.query_params.get('fecha_inicio')
        fecha_fin = self.request.query_params.get('fecha_fin')
        
        if tipo:
            queryset = queryset.filter(tipo=tipo)
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        
        if fecha_inicio and fecha_fin:
            try:
                fecha_inicio = datetime.strptime(fecha_inicio, '%Y-%m-%d').date()
                fecha_fin = datetime.strptime(fecha_fin, '%Y-%m-%d').date()
                queryset = queryset.filter(fecha__range=[fecha_inicio, fecha_fin])
            except ValueError:
                pass
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)
    
    @action(detail=False, methods=['get'])
    def resumen(self, request):
        """Resumen de gastos por tipo"""
        periodo = request.query_params.get('periodo', 'mes')
        hoy = timezone.now()
        
        if periodo == 'mes':
            fecha_inicio = hoy.replace(day=1)
        elif periodo == 'semana':
            fecha_inicio = hoy - timedelta(days=hoy.weekday())
        else:  # año
            fecha_inicio = hoy.replace(month=1, day=1)
        
        gastos = Gasto.objects.filter(fecha__gte=fecha_inicio.date())
        
        resumen = gastos.values('tipo').annotate(
            total=Sum('valor'),
            count=Count('id')
        ).order_by('-total')
        
        total = gastos.aggregate(total=Sum('valor'))['total'] or 0
        
        return Response({
            'periodo': periodo,
            'total': float(total),
            'resumen': list(resumen),
        })

class VisitaViewSet(viewsets.ModelViewSet):
    serializer_class = VisitaSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Visita.objects.all()
        user = self.request.user
        
        # Operarios solo ven sus visitas
        if user.rol == 'operario':
            queryset = queryset.filter(operario=user)
        
        # Filtros
        maquina_id = self.request.query_params.get('maquina_id')
        estado = self.request.query_params.get('estado')
        
        if maquina_id:
            queryset = queryset.filter(maquina_id=maquina_id)
        if estado:
            queryset = queryset.filter(estado=estado)
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(operario=self.request.user)
    
    @action(detail=True, methods=['post'])
    def iniciar(self, request, pk=None):
        """Iniciar una visita"""
        visita = self.get_object()
        
        if visita.estado != 'programada':
            return Response(
                {'error': 'Solo se pueden iniciar visitas programadas'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        visita.estado = 'en_progreso'
        visita.fecha_inicio = timezone.now()
        visita.save()
        
        # Crear conteo pre-visita
        conteo = Conteo.objects.create(
            maquina=visita.maquina,
            tipo='pre_visita',
            usuario=request.user
        )
        
        # Registrar estado actual del inventario
        for inventario in visita.maquina.inventarios.all():
            ConteoDetalle.objects.create(
                conteo=conteo,
                inventario=inventario,
                cantidad=inventario.stock_actual
            )
        
        serializer = self.get_serializer(visita)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def finalizar(self, request, pk=None):
        """Finalizar una visita"""
        visita = self.get_object()
        
        if visita.estado != 'en_progresso':
            return Response(
                {'error': 'Solo se pueden finalizar visitas en progreso'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Actualizar inventario con lo surtido
        inventario_data = request.data.get('inventario', [])
        for item in inventario_data:
            try:
                inventario = InventarioMaquina.objects.get(
                    id=item['id'],
                    maquina=visita.maquina
                )
                inventario.stock_actual = item['stock_actual']
                inventario.stock_surtido = item['stock_actual']
                inventario.save()
            except (InventarioMaquina.DoesNotExist, KeyError):
                continue
        
        # Calcular ventas durante la visita
        ventas_visita = visita.ventas.aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia')
        )
        
        visita.total_ventas = ventas_visita['total'] or 0
        visita.total_ganancias = ventas_visita['ganancia'] or 0
        visita.estado = 'completada'
        visita.fecha_fin = timezone.now()
        visita.save()
        
        # Crear conteo post-visita
        conteo = Conteo.objects.create(
            maquina=visita.maquina,
            tipo='post_visita',
            usuario=request.user
        )
        
        for inventario in visita.maquina.inventarios.all():
            ConteoDetalle.objects.create(
                conteo=conteo,
                inventario=inventario,
                cantidad=inventario.stock_actual
            )
        
        serializer = self.get_serializer(visita)
        return Response(serializer.data)

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
        
        hoy = timezone.now().date()
        mes_actual = hoy.replace(day=1)
        
        # Totales generales
        total_maquinas = Maquina.objects.count()
        total_productos = Producto.objects.count()
        total_usuarios = Usuario.objects.count()
        
        # Ventas de hoy
        ventas_hoy = Venta.objects.filter(fecha__date=hoy).aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia'),
            cantidad=Sum('cantidad')
        )
        
        # Ventas del mes
        ventas_mes = Venta.objects.filter(fecha__date__gte=mes_actual).aggregate(
            total=Sum('total'),
            ganancia=Sum('ganancia')
        )
        
        # Gastos del mes
        gastos_mes = Gasto.objects.filter(fecha__gte=mes_actual).aggregate(
            total=Sum('valor')
        )
        
        # Máquinas con inventario crítico (< 20%) - CORREGIDO
        maquinas_criticas = Maquina.objects.annotate(
            # Calcular porcentaje promedio por máquina
            porcentaje_calculado=ExpressionWrapper(
                Sum(F('inventarios__stock_actual')) * 100.0 / 
                Coalesce(Sum(F('inventarios__stock_maximo')), 1),
                output_field=FloatField()
            )
        ).filter(
            porcentaje_calculado__lt=20
        ).distinct().count()
        
        # Productos más vendidos del mes
        productos_top = Venta.objects.filter(
            fecha__date__gte=mes_actual
        ).values(
            'producto__nombre'
        ).annotate(
            cantidad=Sum('cantidad'),
            ventas=Sum('total')
        ).order_by('-cantidad')[:5]
        
        # Máquinas con más ventas del mes
        maquinas_top = Venta.objects.filter(
            fecha__date__gte=mes_actual
        ).values(
            'maquina__nombre'
        ).annotate(
            ventas=Sum('total'),
            ganancia=Sum('ganancia')
        ).order_by('-ventas')[:5]
        
        return Response({
            'resumen': {
                'maquinas': total_maquinas,
                'productos': total_productos,
                'usuarios': total_usuarios,
                'maquinas_criticas': maquinas_criticas,
            },
            'ventas': {
                'hoy': {
                    'total': float(ventas_hoy['total'] or 0),
                    'ganancia': float(ventas_hoy['ganancia'] or 0),
                    'cantidad': ventas_hoy['cantidad'] or 0,
                },
                'mes': {
                    'total': float(ventas_mes['total'] or 0),
                    'ganancia': float(ventas_mes['ganancia'] or 0),
                    'gastos': float(gastos_mes['total'] or 0),
                    'utilidad': float((ventas_mes['ganancia'] or 0) - (gastos_mes['total'] or 0)),
                }
            },
            'top': {
                'productos': list(productos_top),
                'maquinas': list(maquinas_top),
            },
            'alertas': {
                'inventario_critico': maquinas_criticas > 0,
                'sin_ventas_hoy': (ventas_hoy['total'] or 0) == 0,
            }
        })

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