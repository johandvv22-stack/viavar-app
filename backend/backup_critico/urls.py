from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView
from .views import *

router = DefaultRouter()
router.register(r'usuarios', UsuarioViewSet, basename='usuario')
router.register(r'maquinas', MaquinaViewSet, basename='maquina')
router.register(r'productos', ProductoViewSet, basename='producto')
router.register(r'inventario', InventarioMaquinaViewSet, basename='inventario')
router.register(r'ventas', VentaViewSet, basename='venta')
router.register(r'gastos', GastoViewSet, basename='gasto')
router.register(r'visitas', VisitaViewSet, basename='visita')
router.register(r'conteos', ConteoViewSet, basename='conteo')
router.register(r'cierres', CierreMensualViewSet, basename='cierre')

urlpatterns = [
    # Autenticación
    path('token/', LoginView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('profile/', ProfileView.as_view(), name='profile'),
    
    # Dashboard y reportes
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('reportes/general/', ReporteGeneralView.as_view(), name='reporte_general'),
    
    # Rutas de router
    path('', include(router.urls)),
    
    # Rutas especiales
    path('maquinas/<int:pk>/inventario/', MaquinaViewSet.as_view({'get': 'inventario'}), name='maquina-inventario'),
    path('maquinas/<int:pk>/reporte/', MaquinaViewSet.as_view({'get': 'reporte'}), name='maquina-reporte'),
    path('maquinas/estado/', MaquinaViewSet.as_view({'get': 'estado'}), name='maquinas-estado'),
    
    path('productos/categorias/', ProductoViewSet.as_view({'get': 'categorias'}), name='productos-categorias'),
    path('productos/<int:pk>/maquinas/', ProductoViewSet.as_view({'get': 'maquinas'}), name='producto-maquinas'),
    
    path('inventario/<int:pk>/actualizar-stock/', InventarioMaquinaViewSet.as_view({'post': 'actualizar_stock'}), name='inventario-actualizar-stock'),
    
    path('ventas/reporte/', VentaViewSet.as_view({'get': 'reporte'}), name='ventas-reporte'),
    path('ventas/estadisticas/', VentaViewSet.as_view({'get': 'estadisticas'}), name='ventas-estadisticas'),
    
    path('gastos/resumen/', GastoViewSet.as_view({'get': 'resumen'}), name='gastos-resumen'),
    
    path('visitas/<int:pk>/iniciar/', VisitaViewSet.as_view({'post': 'iniciar'}), name='visita-iniciar'),
    path('visitas/<int:pk>/finalizar/', VisitaViewSet.as_view({'post': 'finalizar'}), name='visita-finalizar'),
    
    path('conteos/<int:pk>/detalles/', ConteoViewSet.as_view({'get': 'detalles'}), name='conteo-detalles'),
    
    path('cierres/<int:pk>/calcular/', CierreMensualViewSet.as_view({'post': 'calcular'}), name='cierre-calcular'),
]