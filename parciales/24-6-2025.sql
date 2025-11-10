/*Se requiere armar una estadística que retorne para cada año y familia el clientes que
menos productos diferentes compro y que más monto compro para ese año y familia
Año, Razón Social Cliente, Familia, Cantidad de unidades compradas de esa familia
Los resultados deben ser ordenados por año de menor a mayor y para cada año
ordenados por la familia que menos productos tenga asignados
NOTA: No se permite resolver ninguna columna con un sub-select y tampoco el uso de
sub-selects en el FROM.*/

SELECT YEAR(f.fact_fecha), c1.clie_razon_social, p.prod_familia, sum(item_cantidad)
FROM Factura f
JOIN Cliente c1 ON fact_cliente = c1.clie_codigo
JOIN Item_Factura ON item_numero = f.fact_numero  AND  item_tipo = f.fact_tipo AND item_sucursal = f.fact_sucursal
JOIN Producto p ON item_producto = p.prod_codigo
WHERE c1.clie_codigo = (SELECT TOP 1 fact_cliente 
							FROM Factura 
							JOIN Item_Factura ON item_numero = fact_numero  AND  item_tipo = fact_tipo AND item_sucursal = fact_sucursal
							JOIN Producto ON item_producto = prod_codigo
							WHERE prod_familia = p.prod_familia AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
							GROUP BY fact_cliente
							ORDER BY COUNT(DISTINCT item_producto), SUM(item_cantidad * item_precio) DESC
							)
GROUP BY YEAR(f.fact_fecha),  c1.clie_razon_social, p.prod_familia
ORDER BY 1, COUNT(DISTINCT item_producto)
GO
/*Realizar un stored procedure que calcule e informe la comisión de un vendedor para un
determinado mes. Los parámetros de entrada es código de vendedor, mes y año.
El criterio para calcular la comisión es: 5% del total vendido tomando como importe base
el valor de la factura sin los impuestos del mes a comisionar, a esto se le debe sumar un
plus de 3% más en el caso de que sea el vendedor que más vendió los productos nuevos
en comparación al resto de los vendedores, es decir este plus se le aplica solo a un
vendedor y en caso de igualdad se le otorga al que posea el código de vendedor más
alto. Se considera que un producto es nuevo cuando su primera venta en la empresa se
produjo durante el mes en curso o en alguno de los 4 meses anteriores. De no haber
ventas de productos nuevos en ese periodo, ese plus nunca se aplica.*/

CREATE PROCEDURE comision 
@vendedor CHAR(8),
@mes INT,
@anio INT
AS
BEGIN
	DECLARE @porcentaje DECIMAL(12,2)
	SET @porcentaje = 0.05
	IF @vendedor = (SELECT TOP 1 fact_vendedor 
					FROM Factura
					JOIN Item_Factura ON item_tipo = fact_tipo AND item_numero = fact_numero AND item_sucursal = fact_sucursal
					WHERE YEAR(fact_fecha) = @anio AND MONTH(fact_fecha) = @mes AND dbo.esNuevo(item_producto, @mes, @anio) = 1
					ORDER BY SUM(item_cantidad) DESC, fact_vendedor DESC
					)
	BEGIN
		SET @porcentaje = 0.08
	END
	RETURN (SELECT SUM(fact_total_impuestos) 
			FROM Factura
			WHERE fact_vendedor = @vendedor AND YEAR(fact_fecha) = @anio AND MONTH(fact_fecha) = @mes
			) * @porcentaje
END
GO

CREATE FUNCTION esNuevo(@producto CHAR(8), @mes INT, @anio INT)
RETURNS BIT
AS
BEGIN
	DECLARE @esNuevo BIT
	SET @esNuevo = 0
	DECLARE @primeraVenta SMALLDATETIME
	SET @primeraVenta = (SELECT TOP 1 fact_fecha FROM Factura JOIN Item_Factura ON item_tipo = fact_tipo AND item_numero = fact_numero AND item_sucursal = fact_sucursal WHERE item_producto = @producto ORDER BY fact_fecha)

	IF (DATEDIFF(MONTH, @primeraVenta, DATEFROMPARTS(@anio, @mes, 1)) <= 3)
		SET @esNuevo = 1
	RETURN @esNuevo;
END

