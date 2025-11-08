/*Armar una consulta que muestre para todos los productos:

Producto

Detalle del producto

Detalle composiciOn (si no es compuesto un string SIN COMPOSICION,, si es compuesto un string CON COMPOSICION

Cantidad de Componentes (si no es compuesto, tiene que mostrar 0)

Cantidad de veces que fue comprado por distintos clientes

Nota: No se permiten sub select en el FROM.*/

SELECT p.prod_codigo, p.prod_detalle,
CASE 
	WHEN p.prod_codigo IN (SELECT comp_producto FROM Composicion) THEN 'CON COMPOSICION'
	ELSE 'SIN COMPOSICION'
END,
ISNULL((SELECT COUNT(*) FROM Composicion WHERE comp_producto = p.prod_codigo),0),
COUNT(DISTINCT fact_cliente) 
FROM Producto p
LEFT JOIN Item_Factura ON item_producto = p.prod_codigo
LEFT JOIN Factura ON fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal 
GROUP BY p.prod_codigo, p.prod_detalle
GO
/*Implementar el/los objetos necesarios para implementar la siguiente restriccion en linea:
Cuando se inserta en una venta un COMBO, nunca se debera guardar el producto COMBO, sino, la descomposicion de sus componentes.
 Nota: Se sabe que actualmente todos los articulos guardados de ventas estan descompuestos en sus componentes.*/

 CREATE TRIGGER combosPapu ON Item_Factura INSTEAD OF INSERT
 AS
 BEGIN
	DECLARE @producto CHAR(8), @cant DECIMAL(12,2), @numero CHAR(8), @tipo CHAR(1), @sucursal CHAR(4)
	DECLARE C1 CURSOR FOR 
		SELECT item_producto, item_cantidad, item_numero, item_tipo, item_sucursal 
		FROM inserted
		WHERE item_producto IN (SELECT comp_producto FROM Composicion)
	OPEN C1
	FETCH C1 INTO @producto, @cant, @numero, @tipo, @sucursal
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @componente CHAR(8), @cantComp DECIMAL(12,2), @precioComp DECIMAL(12,2)
		DECLARE C2 CURSOR FOR
			SELECT comp_componente, comp_cantidad, prod_precio
			FROM Composicion 
			JOIN Producto ON comp_componente = prod_codigo
			WHERE comp_producto = @producto
		OPEN C2
		FETCH C2 INTO @componente, @cantComp, @precioComp
		WHILE @@FETCH_STATUS = 0 
		BEGIN
			INSERT INTO Item_Factura (
				item_tipo,
				item_sucursal,
				item_numero,
				item_producto,
				item_cantidad,
				item_precio
				)
				SELECT item_tipo, item_sucursal, item_numero, @componente, @cantComp * @cant, @precioComp * @cantComp * @cantComp
				FROM inserted
				WHERE item_tipo = @tipo AND item_sucursal = @sucursal AND item_numero = @numero
			FETCH C2 INTO @componente, @cantComp, @precioComp
		END
		DELETE FROM Item_Factura 
			WHERE item_producto = @producto AND item_tipo + item_numero + item_sucursal = @tipo + @numero + @sucursal
		CLOSE C2
		DEALLOCATE C2
		FETCH C1 INTO @producto, @cant, @numero, @tipo, @sucursal
	END
	CLOSE C1
	DEALLOCATE C1
 END