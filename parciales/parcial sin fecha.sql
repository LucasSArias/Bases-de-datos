/*Realizar una consulta SQL que retorne para todas las zonas que tengan
2 (dos) o más depósitos.
Detalle Zona
Cantidad de Depósitos x Zona
Cantidad de Productos distintos en los depósitos de esa zona.
Cantidad de Productos distintos vendidos de esos depósitos y zona.
El resultado deberá ser ordenado por la zona que mas empleados tenga
NOTA: No se permite el uso de sub-selects en el FROM.*/

SELECT zona_detalle, COUNT(DISTINCT depo_codigo) cant_depositos, COUNT(DISTINCT stoc_producto) cant_prods, COUNT(DISTINCT item_producto) cant_prods_vendidos
FROM Zona
JOIN DEPOSITO ON depo_zona = zona_codigo
LEFT JOIN Departamento ON depa_zona = zona_codigo
LEFT JOIN Empleado ON empl_departamento = depa_codigo
LEFT JOIN STOCK ON stoc_deposito = depo_codigo
LEFT JOIN Item_Factura ON stoc_producto = item_producto
GROUP BY zona_detalle
HAVING COUNT(DISTINCT depo_codigo) >= 2
ORDER BY COUNT(DISTINCT empl_codigo) DESC
GO

/* 2. Cree el o los objetos necesarios para que controlar que un producto no pueda tener asignado un rubro que tenga más de 20 productos asignados, 
si esto ocurre, hay que asignarle el rubro que menos productos tenga asignado e informar a que producto y que rubro se le asigno.
En la actualidad la regla se cumple y no se sabe la forma en que se accede a la Base de Datos.*/

CREATE TRIGGER controlar ON Producto FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @prod CHAR(8), @rubro CHAR(4), @rubroMenosProd CHAR(4)
	DECLARE C1 CURSOR FOR 
		SELECT prod_codigo, prod_rubro FROM inserted GROUP BY prod_codigo, prod_rubro
	OPEN C1
	FETCH C1 INTO @prod, @rubro 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @rubroMenosProd = (SELECT TOP 1 prod_rubro FROM Producto GROUP BY prod_rubro ORDER BY COUNT(prod_codigo))
		IF @rubro IN (SELECT prod_rubro FROM Producto GROUP BY prod_rubro HAVING COUNT(prod_codigo) > 20)
		BEGIN
			UPDATE Producto 
				SET prod_rubro = @rubroMenosProd
				WHERE prod_codigo = @prod
				PRINT('PRODUCTO: ' + @prod + ' NUEVO RUBRO' + @rubroMenosProd)
		END
		FETCH C1 INTO @prod, @rubro 
	END
	CLOSE C1
	DEALLOCATE C1
END

