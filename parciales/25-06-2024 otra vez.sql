/*La empresa está muy comprometida con el desarrollo sustentable, y como
consecuencia de ello propone cambiar los envases de sus productos por
envases reciclados. Si bien entiende la importancia de este cambio, también es
consciente de los costos que esto conlleva por lo cual se realizará de manera
paulatina
Por tal motivo se solicita un listado con los 5 productos más vendidos y los 5
productos menos vendidos durante el 2012. Comparar la cantidad vendida de
cada uno de estos productos con la cantidad vendida del año anterior e indicar
el string 'Más ventas' o 'Menos ventas', según corresponda. Además indicar el
envase.
A) Producto
B) Comparación año anterior
C) Detalle de Envase
Armar una consulta SQL que retorne esta información.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas
por el usuario para este punto.
NOTA2: Si un producto no tuvo ventas en el año, también debe considerarse
como producto menos vendido. En caso de existir más de 5, solamente mostrar
los 5 primeros en orden alfabético.*/

SELECT prod_codigo,
CASE 
	WHEN SUM(item_cantidad) > (SELECT SUM(i.item_cantidad) FROM Item_Factura i JOIN Factura f ON f.fact_tipo + f.fact_numero + f.fact_sucursal = i.item_tipo + i.item_numero + i.item_sucursal WHERE YEAR(f.fact_fecha) = 2011 AND i.item_producto = prod_codigo)
		THEN 'MAS VENTAS'
	ELSE 'MENOS VENTAS'
END,
enva_detalle
FROM Producto 
JOIN Envases ON prod_envase = enva_codigo
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal
WHERE YEAR(fact_fecha) = 2012 AND (prod_codigo IN (SELECT TOP 5 item_producto 
													FROM Item_Factura 
													JOIN Factura ON fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal
													WHERE YEAR(fact_fecha) = 2012
													GROUP BY item_producto
													ORDER BY SUM(item_cantidad) DESC
													)
													OR prod_codigo IN
													(SELECT TOP 5 prod_codigo
													FROM Producto
													LEFT JOIN Item_Factura ON item_producto = prod_codigo
													LEFT JOIN Factura ON fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal
													WHERE YEAR(fact_fecha) = 2012
													GROUP BY prod_codigo, prod_detalle
													ORDER BY ISNULL(SUM(item_cantidad), 0), prod_detalle 
													)
													)
GROUP BY prod_codigo, enva_detalle
GO 
/*La compañía cumple años y decidió a repartir algunas sorpresas entre sus
clientes. Se pide crear el/los objetos necesarios para que se imprima un cupón
con la leyenda "Recuerde solicitar su regalo sorpresa en su próxima compra a
los clientes que, entre los productos comprados, hayan adquirido algún producto
de los siguientes rubros: PILAS y PASTILLAS y tengan un limite crediticio menor
a $ 15000.*/

CREATE TRIGGER regalo ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @cliente CHAR(6), @limiteCliente DECIMAL(12,2), @producto CHAR(8)
	DECLARE C1 CURSOR FOR
		SELECT fact_cliente, clie_limite_credito, item_producto
		FROM inserted
		JOIN Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		JOIN Cliente ON fact_cliente = clie_codigo
		GROUP BY fact_cliente, clie_limite_credito, item_producto
	OPEN C1
	FETCH C1 INTO @cliente, @limiteCliente, @producto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@producto IN (SELECT prod_codigo FROM Producto WHERE prod_rubro = 'PILAS' OR prod_rubro = 'PASTILLAS') AND @limiteCliente < 15000)
		PRINT('CLIENTE: '+ @cliente+' Recuerde solicitar su regalo sorpresa en su próxima compra')
		FETCH C1 INTO @cliente, @limiteCliente, @producto
	END
END
