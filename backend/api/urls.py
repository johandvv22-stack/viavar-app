from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView
#from .views import recibir_conteo_esp32  # Agregar esta línea
from .views import *
from .views import test_esp32_endpoint
from .views_esp32 import Esp32SlaveViewSet, Esp32LogViewSet, Esp32ComandoViewSet
from .views import RecargaViewSet
from . import views
from .views import (
    test_recibir_conteos_real,
    prueba_final,
    endpoint_que_si_funciona,
    test_recibir_conteo,
    Esp32EstadoDetailView,
    ForzarConteoView,
    ConfigEsp32View,
)

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
router.register(r'recargas', RecargaViewSet, basename='recarga')
router.register(r'esp32-slaves', Esp32SlaveViewSet, basename='esp32-slave')
router.register(r'esp32-logs', Esp32LogViewSet, basename='esp32-log')
router.register(r'esp32-comandos', Esp32ComandoViewSet, basename='esp32-comando')
urlpatterns = [
    # Autenticación
    path('token/', LoginView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('profile/', ProfileView.as_view(), name='profile'),
    
    # Dashboard y reportes
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('reportes/general/', ReporteGeneralView.as_view(), name='reporte_general'),
    
    # Finanzas - Nuevos endpoints
    path('gastos/resumen/', GastoViewSet.as_view({'get': 'resumen'}), name='gastos-resumen'),
    path('cierres/evolucion/', CierreMensualViewSet.as_view({'get': 'evolucion'}), name='cierres-evolucion'),
    path('maquinas/top-facturacion/', MaquinaViewSet.as_view({'get': 'top_facturacion'}), name='maquinas-top-facturacion'),


    # Rutas de router
    path('', include(router.urls)),
    
    # Rutas especiales
    path('maquinas/<int:pk>/inventario/', MaquinaViewSet.as_view({'get': 'inventario'}), name='maquina-inventario'),
    path('maquinas/<int:pk>/reporte/', MaquinaViewSet.as_view({'get': 'reporte'}), name='maquina-reporte'),
    path('maquinas/estado/', MaquinaViewSet.as_view({'get': 'estado'}), name='maquinas-estado'),
    path('maquinas/<int:pk>/faltantes/', views.MaquinaViewSet.as_view({'get': 'faltantes'}), name='maquina-faltantes'),
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

    
    
    # ESP32 Endpoints
    path('esp32/v1/recibir/', endpoint_que_si_funciona, name='esp32-recibir'),
    #path('conteos/recibir/', esp32_recibir_conteos, name='recibir-conteos'),
    path('conteos/recibir/', test_recibir_conteos_real, name='recibir-conteos'),
    path('conteos/recibir/', endpoint_que_si_funciona, name='recibir-conteos'),
    path('prueba-final/', prueba_final, name='prueba-final'),
    path('maquinas/<int:pk>/esp32-estado/', Esp32EstadoDetailView.as_view(), name='esp32-estado'),
    path('maquinas/<int:pk>/forzar-conteo/', ForzarConteoView.as_view(), name='forzar-conteo'),
    path('maquinas/<int:pk>/config-esp32/', ConfigEsp32View.as_view(), name='config-esp32'),

    path('test-esp32/', test_esp32_endpoint, name='test-esp32'),
    path('test-recibir/', test_recibir_conteo, name='recibir-conteos'),
    # Endpoints para que la ESP32 actualice estado y envíe logs (sin necesidad de ID)
    path('maquinas/<str:codigo>/esp32/estado/', Esp32SlaveViewSet.as_view({'post': 'actualizar_estado'}), name='esp32-actualizar-estado'),
    path('maquinas/<str:codigo>/esp32/logs/', Esp32LogViewSet.as_view({'post': 'crear_desde_esp32'}), name='esp32-enviar-logs'),
    path('maquinas/<str:codigo>/esp32/comandos/', Esp32ComandoViewSet.as_view({'get': 'list'}), name='esp32-obtener-comandos'),
]