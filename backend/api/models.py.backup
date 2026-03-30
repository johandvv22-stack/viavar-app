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
    
    class Meta:
        db_table = 'maquinas'
        verbose_name = 'Máquina'
        verbose_name_plural = 'Máquinas'
    
    def __str__(self):
        return f"{self.codigo} - {self.nombre}"
    
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