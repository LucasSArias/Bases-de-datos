/*Realizar una consulta SQL que retorne para todas las zonas que tengan
3 (tres) o más depósitos.
    1) Detalle Zona
    2) Cantidad de Depósitos x Zona
    3) Cantidad de Productos distintos compuestos en sus depósitos
    4) Producto mas vendido en el año 2012 que tenga stock en al menos
    uno de sus depósitos.
    5) Mejor encargado perteneciente a esa zona (El que mas vendió en la
        historia).
El resultado deberá ser ordenado por monto total vendido del encargado
descendiente.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones
definidas por el usuario para este punto.
*/

SELECT z.zona_detalle, COUNT(d.depo_codigo) depos_zona, COUNT(DISTINCT s.stoc_producto) productos_compuestos,
(SELECT TOP 1 item_producto 
    FROM Item_Factura
    JOIN Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
    JOIN STOCK ON stoc_producto = item_producto
    WHERE YEAR(fact_fecha) = 2012 AND stoc_cantidad > 0 AND stoc_deposito = d.depo_codigo
    GROUP BY item_producto
    ORDER BY SUM(item_cantidad) DESC
    )
FROM Zona z
JOIN DEPOSITO d ON d.depo_zona = z.zona_codigo
JOIN STOCK s ON s.stoc_deposito = d.depo_codigo
WHERE s.stoc_producto IN (SELECT comp_producto FROM Composicion) 
GROUP BY z.zona_detalle, d.depo_codigo
HAVING COUNT(d.depo_codigo) >= 3