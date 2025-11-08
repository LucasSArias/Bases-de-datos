/* 1. Realizar una consulta SQL que muestre la siguiente informacion para los clientes que hayan
comprado productos en mpas de tres rubros diferentes en 2012 y que no compro en años impares
El numero de fila
El codigo del cliente
el nombre del cliente
la cantidad total comprada por el cliente
la categoria en la que más compro en 2012
El resultado debe estar ordenado por la cantidad total comprada de mayor a menor 
*/

SELECT c.clie_codigo, c.clie_razon_social, SUM(i.item_cantidad), 
(SELECT TOP 1 prod_familia 
	FROM Producto
	JOIN Item_Factura ON item_producto = prod_codigo
	JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
	WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo
	GROUP BY prod_familia
	ORDER BY COUNT(*) DESC
	)
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE YEAR(fact_fecha) = 2012 AND c.clie_codigo NOT IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha)%2 <> 0)
GROUP BY c.clie_codigo, c.clie_razon_social
HAVING COUNT(DISTINCT prod_rubro) > 3

/* 2. Implementar los objetos necesarios para registrar, en tiempo real, los 10 productos
mas vendidos por anio en una tabla especifica. Esta tabla debe contener exclusivamente la info requerida
sin incluir filas adicionales. 

Los mas vendidos se define como aquellos productos con el mayor numero de unidades vendidas.
*/
-- NO ES DIFICIL ES PAJONA

