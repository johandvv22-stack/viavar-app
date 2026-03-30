from django.utils import timezone
from .models import Maquina, InventarioMaquina, Venta, Conteo, Recarga#DetalleConteo 
import logging

logger = logging.getLogger(__name__)

def procesar_lecturas_esp32(maquina, batch_id, lecturas_raw, timestamp_recepcion):
    """
    Procesa las lecturas de la ESP32, guarda detalles de conteo y genera ventas/recargas
    """
    resultados = {
        'ventas_creadas': 0,
        'recargas_creadas': 0,
        'errores': []
    }

    # Crear un registro de conteo principal
    conteo = Conteo.objects.create(
        maquina=maquina,
        tipo='periodico',
        fecha_hora=timestamp_recepcion,
        usuario=None,  # Viene de ESP32, no hay usuario
        observaciones=f"Batch: {batch_id}"
    )

    for lectura in lecturas_raw:
        posicion = lectura['posicion']
        nueva_cantidad = lectura['cantidad']

        # 1. Buscar el producto en esa posición
        try:
            inventario = InventarioMaquina.objects.get(
                maquina=maquina,
                codigo_espiral=posicion
            )
        except InventarioMaquina.DoesNotExist:
            logger.warning(f"Posición {posicion} no configurada para máquina {maquina.codigo}")
            resultados['errores'].append(f"Posición {posicion} no configurada")
            continue

        # 2. Obtener stock anterior (del inventario actual)
        cantidad_anterior = inventario.stock_actual

        # 3. Crear detalle de conteo
        #DetalleConteo.objects.create(
         #   conteo=conteo,
          #  inventario=inventario,
           # cantidad=nueva_cantidad
        #)

        # 4. Comparar y generar eventos
        if cantidad_anterior > nueva_cantidad:
                        # VENTA: disminuyó el stock
            diferencia = cantidad_anterior - nueva_cantidad
            total_venta = diferencia * inventario.precio_venta
            costo_total = diferencia * inventario.producto.precio_compra
            ganancia = total_venta - costo_total
            
            Venta.objects.create(
                maquina=maquina,
                producto=inventario.producto,
                inventario=inventario,
                fecha=timestamp_recepcion,
                cantidad=diferencia,
                precio_unitario=inventario.precio_venta,
                total=total_venta,
                costo=costo_total,
                ganancia=ganancia
            )
            resultados['ventas_creadas'] += 1
            logger.info(f"Venta creada: {diferencia} x {inventario.producto.nombre}")

        elif cantidad_anterior < nueva_cantidad:
            # RECARGA: aumentó el stock
            diferencia = nueva_cantidad - cantidad_anterior
            
            # Calcular costos
            costo_total = diferencia * inventario.producto.precio_compra
            
            Recarga.objects.create(
                maquina=maquina,
                producto=inventario.producto,
                inventario=inventario,
                cantidad=diferencia,
                fecha=timestamp_recepcion,
                origen='esp32',
                costo_unitario=inventario.producto.precio_compra,
                costo_total=costo_total,
                precio_venta=inventario.precio_venta,
                conteo=conteo  # Asociar al conteo creado
            )
            resultados['recargas_creadas'] += 1
            logger.info(f"Recarga creada: {diferencia} x {inventario.producto.nombre}")
        # 5. Actualizar el stock actual
        inventario.stock_actual = nueva_cantidad
        inventario.save()

    return resultados