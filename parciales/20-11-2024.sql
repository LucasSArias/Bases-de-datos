/* 1. Consulta SQL para analizar clientes con patrones de cmpra especificos

Se debe identificar clientes que realizarion una compra inicial y luego volvieron a 
comprar despues de 5 meses o más 

La consulta debe mostrar 
    
El numero de fila: identificador secuencial del resultado
el codigo del cliente id unico del cliente
el nombre del cliente: nombre asociado al cliente
cantidad total comprada: total de productos distintos adquiridos por el cliente
total facturado: importe total factura al cliente
El resultado debe estsr ordenado de forma descendente por la cantidad de productos 
adquiridos por cada cliente
*/

-- PUNTO DE MIERDA QUIQUEEEEE
SELECT c.clie_codigo, c.clie_razon_social
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
GROUP BY c.clie_codigo, c.clie_razon_social
HAVING DATEDIFF(MONTH, MIN(f.fact_fecha), (SELECT TOP 1 fact_fecha
                                        FROM Factura
                                        WHERE fact_cliente = c.clie_codigo
                                        AND fact_fecha > (SELECT MIN(fact_fecha) FROM Factura WHERE fact_cliente = c.clie_codigo)
                                        ORDER BY fact_fecha asc) ) >= 5
