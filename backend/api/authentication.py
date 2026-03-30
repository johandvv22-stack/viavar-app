from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from .models import Maquina
import logging

logger = logging.getLogger(__name__)

class ESP32APIAuthentication(BaseAuthentication):
    """
    Autenticación personalizada para ESP32 usando una API Key en el header.
    """
    def authenticate(self, request):
        # Buscar la clave en el header 'X-API-Key'
        api_key = request.META.get('HTTP_X_API_KEY')
        
        print(f"[DEBUG] Header X-API-Key recibido: {api_key}")  # Temporal
        
        if not api_key:
            print("[DEBUG] No se encontró X-API-Key en headers")
            return None

        try:
            # Buscar una máquina con esa API key
            maquina = Maquina.objects.get(api_key=api_key)
            print(f"[DEBUG] Máquina encontrada: {maquina.codigo}")
            return (maquina, None)
        except Maquina.DoesNotExist:
            print(f"[DEBUG] No existe máquina con API key: {api_key}")
            raise AuthenticationFailed('API Key inválida.')