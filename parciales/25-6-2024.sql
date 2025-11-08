/*Sabiendo que si un producto no es vendido en un depósito determinado entonces
no posee registros en él.
Se requiere una consulta sql que para todos los productos que se quedaron sin
stock en un depósito (cantidad 0 o nula) y poseen un stock mayor al punto de
reposición en otro deposito devuelva:
1- Código de producto
2- Detalle del producto
3- Domicilio del depósito sin stock
4- Cantidad de depósitos con un stock superior al punto de reposición
La consulta debe ser ordenada por el código de producto.
NOTA: No se permite el uso de sub-selects en el FROM.*/

SELECT p.prod_codigo,
	p.prod_detalle, 
	d.depo_domicilio,
	(SELECT COUNT(*) FROM STOCK WHERE stoc_producto = p.prod_codigo AND stoc_cantidad > stoc_punto_reposicion) depos_stoc_mayor_reposicion
FROM Producto p
JOIN STOCK s ON s.stoc_producto = p.prod_codigo
JOIN DEPOSITO d ON d.depo_codigo = s.stoc_deposito
WHERE EXISTS(SELECT * FROM STOCK WHERE stoc_producto = p.prod_codigo AND stoc_cantidad > stoc_punto_reposicion)
AND s.stoc_cantidad = 0 OR stoc_cantidad IS NULL
ORDER BY 1
GO
/*Dado el contexto inflacionario se tiene que aplicar un control en el cual nunca se
permita vender un producto a un precio que no esté entre 0%-5% del precio de
venta del producto el mes anterior, ni tampoco que esté en más de un 50% el
precio del mismo producto que hace 12 meses atrás. Aquellos productos nuevos,
o que no tuvieron ventas en meses anteriores no debe considerar esta regla ya
que no hay precio de referencia.*/

CREATE FUNCTION valorHistorico(@producto CHAR(8), @fecha SMALLDATETIME, @mesesAtras INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
	RETURN (SELECT TOP 1 item_precio
			FROM Item_Factura
			JOIN Factura ON item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
			WHERE item_producto = @producto
			AND fact_fecha BETWEEN DATEADD(MONTH, -@mesesAtras, @fecha) AND DATEADD(MONTH, -@mesesAtras + 1, @fecha)
			ORDER BY fact_fecha DESC
			)
END
GO

CREATE TRIGGER controlInflacion ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @producto CHAR(8), @precio DECIMAL(12,2), @precioMesAnterior DECIMAL(12,2), @precioAnioAnterior DECIMAL(12,2)
	DECLARE C1 CURSOR FOR
		SELECT item_producto, item_precio
		FROM inserted
		WHERE dbo.valorHistorico(item_producto, GETDATE(), 1) IS NOT NULL AND dbo.valorHistorico(item_producto, GETDATE(), 12) IS NOT NULL
	OPEN C1
	FETCH C1 INTO @producto, @precio
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@precio > dbo.valorHistorico(@producto, GETDATE(), 1) * 1.05 OR @precio > dbo.valorHistorico(@producto, GETDATE(), 12) * 1.5)
			ROLLBACK TRANSACTION
		FETCH C1 INTO @producto, @precio
	END
END
GO

