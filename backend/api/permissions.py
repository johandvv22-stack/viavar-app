from rest_framework import permissions

class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Permite a cualquiera leer, pero solo a administradores escribir.
    """
    def has_permission(self, request, view):
        # Permitir siempre métodos seguros (GET, HEAD, OPTIONS)
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Solo administradores pueden escribir
        return request.user.is_authenticated and request.user.rol == 'admin'

class IsAdmin(permissions.BasePermission):
    """
    Solo permite acceso a administradores.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.rol == 'admin'

class IsOperario(permissions.BasePermission):
    """
    Solo permite acceso a operarios.
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.rol == 'operario'

class IsAdminOrSelf(permissions.BasePermission):
    """
    Permite a administradores ver todo, usuarios normales solo su información.
    """
    def has_object_permission(self, request, view, obj):
        # Administradores pueden hacer cualquier cosa
        if request.user.rol == 'admin':
            return True
        
        # Usuarios solo pueden ver/editar su propia información
        if hasattr(obj, 'usuario'):
            return obj.usuario == request.user
        elif hasattr(obj, 'operario'):
            return obj.operario == request.user
        elif hasattr(obj, 'user'):
            return obj.user == request.user
        
        return obj == request.user

class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Permite acceso si es el dueño del objeto o si es administrador.
    """
    def has_object_permission(self, request, view, obj):
        if request.user.rol == 'admin':
            return True
        
        # Verificar diferentes tipos de propiedad
        if hasattr(obj, 'usuario'):
            return obj.usuario == request.user
        elif hasattr(obj, 'operario'):
            return obj.operario == request.user
        elif hasattr(obj, 'user'):
            return obj.user == request.user
        
        return False

class VisitaPermission(permissions.BasePermission):
    """
    Permisos especiales para visitas:
    - Operarios pueden crear y ver sus visitas
    - Admin puede ver/modificar todas
    """
    def has_permission(self, request, view):
        if request.method in ['POST', 'GET']:
            return request.user.is_authenticated
        return request.user.is_authenticated and request.user.rol == 'admin'
    
    def has_object_permission(self, request, view, obj):
        if request.user.rol == 'admin':
            return True
        return obj.operario == request.user
class IsESP32(permissions.BasePermission):
    """
    Permiso que permite acceso solo a instancias de Maquina autenticadas.
    """
    def has_permission(self, request, view):
        # Verificación más robusta
        if request.user is None:
            return False
        from .models import Maquina
        return isinstance(request.user, Maquina)
class IsAdminOrOperario(permissions.BasePermission):
    """
    Permiso para permitir acceso a admin y operario.
    El admin tiene acceso total, el operario solo lectura.
    """
    def has_permission(self, request, view):
        # Verificar que el usuario está autenticado
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Si es admin, tiene acceso total
        if request.user.rol == 'admin':
            return True
        
        # Si es operario, solo permitir métodos seguros (GET, HEAD, OPTIONS)
        if request.user.rol == 'operario':
            return request.method in permissions.SAFE_METHODS
        
        return False

    def has_object_permission(self, request, view, obj):
        # Si es admin, puede hacer cualquier cosa
        if request.user.rol == 'admin':
            return True
        
        # Si es operario, solo lectura
        if request.user.rol == 'operario':
            return request.method in permissions.SAFE_METHODS
        
        return False