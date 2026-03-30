from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone

class Usuario(AbstractUser):
    ROLES = (
        ('admin', 'Administrador'),
        ('operario', 'Operario'),
    )
    
    rol = models.CharField(max_length=20, choices=ROLES, default='operario')
    telefono = models.CharField(max_length=15, blank=True, null=True)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    
    # Agrega esto para que funcione con AbstractUser:
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name='groups',
        blank=True,
        help_text='The groups this user belongs to.',
        related_name="usuario_groups",
        related_query_name="usuario",
    )
    
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name='user permissions',
        blank=True,
        help_text='Specific permissions for this user.',
        related_name="usuario_permissions",
        related_query_name="usuario",
    )
    
    class Meta:
        db_table = 'usuarios'
        verbose_name = 'Usuario'
        verbose_name_plural = 'Usuarios'
    
    def __str__(self):
        return f"{self.username} ({self.get_rol_display()})"

class Maquina(models.Model):
    ESTADOS = (
        ('activo', 'Activo'),
        ('inactivo', 'Inactivo'),
        ('mantenimiento', 'En Mantenimiento'),
    )
    
    nombre = models.CharField(max_length=100)
    codigo = models.CharField(max_length=20, unique=True)
    ubicacion = models.CharField(max_length=200)
    latitud = models.FloatField(null=True, blank=True)
    longitud = models.FloatField(null=True, blank=True)
    capacidad_total = models.IntegerField(default=50)
    estado = models.CharField(max_length=20, choices=ESTADOS, default='activo')
    fecha_instalacion = models.DateField(default=timezone.now)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    api_key = models.CharField(max_length=100, unique=True, null=True, editable=False)

    class Meta:
        db_table = 'maquinas'
        verbose_name = 'Máquina'
        verbose_name_plural = 'Máquinas'
    
    def __str__(self):
        return f"{self.codigo} - {self.nombre}"
    
    def save(self, *args, **kwargs):
        if not self.api_key:
            import secrets
            self.api_key = f"mk_{self.codigo.lower()}_{secrets.token_urlsafe(32)}"
        super().save(*args, **kwargs)

    @property
    def porcentaje_surtido(self):
        try:
            inventarios = self.inventarios.all()
            if not inventarios:
                return 0
            total_actual = sum(inv.stock_actual for inv in inventarios)
            total_maximo = sum(inv.stock_maximo for inv in inventarios)
            return round((total_actual / total_maximo) * 100, 2) if total_maximo > 0 else 0
        except:
            return 0

class Producto(models.Model):
    CATEGORIAS = (
        ('paquete_grande', 'Paquete Grande'),
        ('paquete_mediano', 'Paquete Mediano'),
        ('paquete_pequeno', 'Paquete Pequeño'),
        ('liquido_grande', 'Líquido Grande'),
        ('liquido_pequeno', 'Líquido Pequeño'),
        ('cafe', 'Café'),
        ('snack', 'Snack'),
        ('bebida', 'Bebida'),
    )
    
    codigo = models.CharField(max_length=50, unique=True)
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    categoria = models.CharField(max_length=20, choices=CATEGORIAS)
    precio_compra = models.DecimalField(max_digits=10, decimal_places=2)
    precio_venta_sugerido = models.DecimalField(max_digits=10, decimal_places=2)
    imagen = models.ImageField(upload_to='productos/', blank=True, null=True)
    estado = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'productos'
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'
    
    def __str__(self):
        return f"{self.codigo} - {self.nombre}"
    
    @property
    def ganancia_unitaria(self):
        return self.precio_venta_sugerido - self.precio_compra

# 🎯 ¡ESTE ES EL MODELO QUE FALTA!
class InventarioMaquina(models.Model):
    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='inventarios')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    codigo_espiral = models.CharField(max_length=20)
    stock_maximo = models.IntegerField()
    stock_surtido = models.IntegerField(default=0)
    stock_actual = models.IntegerField(default=0)
    precio_venta = models.DecimalField(max_digits=10, decimal_places=2)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'inventario_maquina'
        unique_together = ('maquina', 'codigo_espiral')
        verbose_name = 'Inventario Máquina'
        verbose_name_plural = 'Inventarios Máquinas'
    
    def __str__(self):
        return f"{self.maquina.codigo} - {self.producto.nombre}"
    
    @property
    def cantidad_faltante(self):
        return self.stock_maximo - self.stock_actual
    
    @property
    def porcentaje_surtido(self):
        if self.stock_maximo > 0:
            return round((self.stock_actual / self.stock_maximo) * 100, 2)
        return 0
    
    @property
    def cantidad_vendida(self):
        return self.stock_surtido - self.stock_actual

class Conteo(models.Model):
    TIPOS = (
        ('periodico', 'Periódico (15 min)'),
        ('pre_visita', 'Pre-Visita'),
        ('post_visita', 'Post-Visita'),
        ('manual', 'Manual'),
    )
    
    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='conteos')
    tipo = models.CharField(max_length=20, choices=TIPOS)
    fecha_hora = models.DateTimeField(default=timezone.now)
    usuario = models.ForeignKey(Usuario, on_delete=models.SET_NULL, null=True, blank=True)
    observaciones = models.TextField(blank=True, null=True)
    
    class Meta:
        db_table = 'conteos'
        verbose_name = 'Conteo'
        verbose_name_plural = 'Conteos'
        ordering = ['-fecha_hora']
    
    def __str__(self):
        return f"Conteo {self.tipo} - {self.maquina.codigo} - {self.fecha_hora}"

class ConteoDetalle(models.Model):
    conteo = models.ForeignKey(Conteo, on_delete=models.CASCADE, related_name='detalles')
    inventario = models.ForeignKey(InventarioMaquina, on_delete=models.CASCADE)
    cantidad = models.IntegerField()
    
    class Meta:
        db_table = 'conteo_detalles'
        verbose_name = 'Detalle de Conteo'
        verbose_name_plural = 'Detalles de Conteo'

class Visita(models.Model):
    ESTADOS = (
        ('programada', 'Programada'),
        ('en_ruta', 'En Ruta'),
        ('en_progreso', 'En Progreso'),
        ('completada', 'Completada'),
        ('cancelada', 'Cancelada'),
    )
    
    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='visitas')
    operario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='visitas')
    fecha_programada = models.DateTimeField()
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_fin = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default='programada')
    observaciones = models.TextField(blank=True, null=True)
    total_ventas = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_ganancias = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'visitas'
        verbose_name = 'Visita'
        verbose_name_plural = 'Visitas'
        ordering = ['-fecha_programada']
    
    def __str__(self):
        return f"Visita {self.maquina.codigo} - {self.operario.username} - {self.estado}"
    
    @property
    def duracion(self):
        if self.fecha_inicio and self.fecha_fin:
            return self.fecha_fin - self.fecha_inicio
        return None

class Venta(models.Model):
    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='ventas')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    inventario = models.ForeignKey(InventarioMaquina, on_delete=models.SET_NULL, null=True)
    visita = models.ForeignKey(Visita, on_delete=models.SET_NULL, null=True, blank=True, related_name='ventas')
    fecha = models.DateTimeField(default=timezone.now)
    cantidad = models.IntegerField()
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    costo = models.DecimalField(max_digits=10, decimal_places=2)
    ganancia = models.DecimalField(max_digits=10, decimal_places=2)
    
    class Meta:
        db_table = 'ventas'
        verbose_name = 'Venta'
        verbose_name_plural = 'Ventas'
        ordering = ['-fecha']
    
    def __str__(self):
        return f"Venta {self.producto.nombre} - {self.cantidad} und - ${self.total}"
    
    def save(self, *args, **kwargs):
        if not self.total:
            self.total = self.cantidad * self.precio_unitario
        if not self.costo:
            self.costo = self.cantidad * self.producto.precio_compra
        if not self.ganancia:
            self.ganancia = self.total - self.costo
        super().save(*args, **kwargs)

class Gasto(models.Model):
    TIPOS = (
        ('transporte', 'Transporte'),
        ('operario', 'Operario'),
        ('mantenimiento', 'Mantenimiento'),
        ('arrendamiento', 'Arrendamiento'),
        ('reposicion', 'Reposición de Productos'),
        ('servicios', 'Servicios Públicos'),
        ('otros', 'Otros'),
    )
    
    tipo = models.CharField(max_length=20, choices=TIPOS)
    descripcion = models.TextField()
    valor = models.DecimalField(max_digits=10, decimal_places=2)
    maquina = models.ForeignKey(Maquina, on_delete=models.SET_NULL, null=True, blank=True, related_name='gastos')
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='gastos')
    fecha = models.DateField(default=timezone.now)
    comprobante = models.ImageField(upload_to='comprobantes/', blank=True, null=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'gastos'
        verbose_name = 'Gasto'
        verbose_name_plural = 'Gastos'
        ordering = ['-fecha']
    
    def __str__(self):
        return f"Gasto {self.tipo} - ${self.valor} - {self.fecha}"

class CierreMensual(models.Model):
    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='cierres')
    mes = models.IntegerField()
    año = models.IntegerField()
    ventas_totales = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    gastos_totales = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    ganancia_neta = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    observaciones = models.TextField(blank=True, null=True)
    responsable = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='cierres')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_cierre = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'cierres_mensuales'
        verbose_name = 'Cierre Mensual'
        verbose_name_plural = 'Cierres Mensuales'
        unique_together = ('maquina', 'mes', 'año')
    
    def __str__(self):
        return f"Cierre {self.maquina.codigo} - {self.mes}/{self.año}"
    
    def calcular_totales(self):
        # Este método se llamará para calcular los totales
        pass

class Recarga(models.Model):
    """Registro de recargas de productos en máquinas"""
    TIPOS = (
        ('manual', 'Manual'),
        ('esp32', 'Automática por ESP32'),
        ('programada', 'Programada'),
    )

    maquina = models.ForeignKey(Maquina, on_delete=models.CASCADE, related_name='recargas')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='recargas')
    inventario = models.ForeignKey(InventarioMaquina, on_delete=models.CASCADE, related_name='recargas')
    visita = models.ForeignKey('Visita', on_delete=models.SET_NULL, null=True, blank=True, related_name='recargas')
    cantidad = models.IntegerField()
    fecha = models.DateTimeField(default=timezone.now)
    origen = models.CharField(max_length=20, choices=TIPOS, default='esp32')
    observaciones = models.TextField(blank=True, null=True)
    costo_unitario = models.DecimalField(max_digits=10, decimal_places=2, help_text="Costo de compra del producto")
    costo_total = models.DecimalField(max_digits=10, decimal_places=2)
    precio_venta = models.DecimalField(max_digits=10, decimal_places=2, help_text="Precio al que se venderá")
    
    # Relación con conteo (opcional)
    conteo = models.ForeignKey(Conteo, on_delete=models.SET_NULL, null=True, blank=True, related_name='recargas')

    class Meta:
        db_table = 'recargas'
        verbose_name = 'Recarga'
        verbose_name_plural = 'Recargas'
        ordering = ['-fecha']

    def save(self, *args, **kwargs):
        # Calcular costo total automáticamente si no se proporciona
        if not self.costo_total and self.cantidad and self.costo_unitario:
            self.costo_total = self.cantidad * self.costo_unitario
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Recarga {self.cantidad} x {self.producto.nombre} - {self.maquina.codigo} - {self.fecha}"

class Esp32Estado(models.Model):
    ESTADOS_ESP32 = [  # 4 espacios
        ('online', 'Online'),
        ('offline', 'Offline'),
        ('storage', 'Storage'),
        ('error', 'Error'),
    ]

    maquina = models.OneToOneField(  # 4 espacios
        'Maquina', 
        on_delete=models.CASCADE, 
        related_name='esp32_estado'
    ) 
    ultima_conexion = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(
        max_length=20, 
        choices=ESTADOS_ESP32, 
        default='offline'
    )
    memoria_ocupada = models.IntegerField(default=0, help_text="En bytes")
    firmware_version = models.CharField(max_length=50, blank=True)
    intervalo_actual = models.IntegerField(
        default=900, 
        help_text="Intervalo de lectura en segundos"
    )
    batch_pendientes = models.IntegerField(
        default=0, 
        help_text="Número de batches sin enviar (reportado por ESP32)"
    )
    ultimo_reinicio = models.DateTimeField(null=True, blank=True)
    alertas = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = 'esp32_estados'
        verbose_name = 'Estado ESP32'
        verbose_name_plural = 'Estados ESP32'

    def __str__(self):
        return f"ESP32 - {self.maquina.codigo} - {self.estado}"

    def actualizar_estado(self, data_estado):
        from django.utils import timezone
        self.ultima_conexion = timezone.now()
        self.estado = data_estado.get('estado', 'online')
        self.memoria_ocupada = data_estado.get('memoria_ocupada', 0)
        self.firmware_version = data_estado.get('firmware', self.firmware_version)
        self.batch_pendientes = data_estado.get('batches_pendientes', 0)
        self.save()
    
# ==================== ESP32 MODELS ====================
# 1. Esp32Slave primero
class Esp32Slave(models.Model):
    """
    Representa una bandeja (esclava) dentro de una máquina.
    Cada bandeja tiene su propio ESP32-C3 y controla una columna de productos.
    """
    ESTADO_CHOICES = [
        ('online', 'En línea'),
        ('offline', 'Desconectada'),
        ('reading', 'Leyendo sensores'),
        ('error', 'Error'),
        ('calibrating', 'Calibrando'),
    ]

    maquina = models.ForeignKey(
        'Maquina',
        on_delete=models.CASCADE,
        related_name='slaves'
    )
    posicion = models.CharField(max_length=10, help_text="Identificador de la bandeja (A, B, C, ...)")
    codigo_producto = models.CharField(max_length=50, blank=True, null=True, help_text="Código del producto en esta bandeja (opcional)")
    firmware_version = models.CharField(max_length=20, default='v1.0')
    ultima_conexion = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='offline')
    error_mensaje = models.TextField(blank=True, null=True)
    # Parámetros de calibración
    distancia_min = models.FloatField(default=0, help_text="Distancia mínima en mm para considerar producto presente")
    distancia_max = models.FloatField(default=200, help_text="Distancia máxima en mm")
    # Mapeo de posiciones de la espiral a códigos de producto (lista de strings)
    posiciones = models.JSONField(default=list, blank=True, help_text="Lista de códigos de espiral en orden físico")
    # Datos de la última lectura (caché para mostrar en la app)
    ultima_lectura = models.JSONField(default=dict, blank=True, help_text="Última lectura recibida: {posicion: cantidad, ...}")
    ultima_lectura_fecha = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.maquina.codigo} - Bandeja {self.posicion}"

    class Meta:
        unique_together = ['maquina', 'posicion']


# 2. Esp32Log después de Esp32Slave
class Esp32Log(models.Model):
    """
    Registro de eventos y errores generados por la ESP32 (maestro o esclavas).
    """
    NIVEL_CHOICES = [
        ('INFO', 'Info'),
        ('WARNING', 'Advertencia'),
        ('ERROR', 'Error'),
    ]

    maquina = models.ForeignKey('Maquina', on_delete=models.CASCADE, related_name='logs')
    slave = models.ForeignKey(Esp32Slave, on_delete=models.SET_NULL, null=True, blank=True, related_name='logs')
    timestamp = models.DateTimeField(auto_now_add=True)
    nivel = models.CharField(max_length=20, choices=NIVEL_CHOICES, default='INFO')
    mensaje = models.TextField()
    datos_extra = models.JSONField(default=dict, blank=True, help_text="Información adicional (ej. batch_id, errores específicos)")

    def __str__(self):
        return f"[{self.timestamp}] {self.maquina.codigo} - {self.get_nivel_display()}: {self.mensaje[:50]}"


# 3. Esp32Comando después de Esp32Slave y Esp32Log
class Esp32Comando(models.Model):
    """
    Comando pendiente para la ESP32 (cola de comandos).
    El maestro consulta esta tabla periódicamente y ejecuta los comandos.
    """
    COMANDO_CHOICES = [
        ('leer_todo', 'Leer todas las bandejas'),
        ('leer_bandeja', 'Leer una bandeja específica'),
        ('leer_posicion', 'Leer una posición específica en una bandeja'),
        ('calibrar', 'Calibrar una bandeja'),
        ('test', 'Ejecutar prueba de hardware'),
        ('reiniciar', 'Reiniciar esclava'),
        ('actualizar_firmware', 'Actualizar firmware (avanzado)'),
    ]

    maquina = models.ForeignKey('Maquina', on_delete=models.CASCADE, related_name='comandos')
    slave = models.ForeignKey(Esp32Slave, on_delete=models.SET_NULL, null=True, blank=True, related_name='comandos')
    comando = models.CharField(max_length=50, choices=COMANDO_CHOICES)
    parametros = models.JSONField(default=dict, blank=True, help_text="Parámetros adicionales del comando (ej. posicion, batch_id)")
    creado_en = models.DateTimeField(auto_now_add=True)
    ejecutado = models.BooleanField(default=False)
    ejecutado_en = models.DateTimeField(null=True, blank=True)
    respuesta = models.JSONField(default=dict, blank=True, help_text="Respuesta del comando (si aplica)")

    def __str__(self):
        return f"Comando {self.get_comando_display()} para {self.maquina.codigo}{' - ' + self.slave.posicion if self.slave else ''} - {'Ejecutado' if self.ejecutado else 'Pendiente'}"