/*1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.*/

alter FUNCTION ej1 (@articulo char(8), @deposito char(2))
RETURNS char(50)
BEGIN
	declare @maximo numeric(12,2), @stock numeric(12,2)
	select @stock = stoc_cantidad, @maximo = isnull(stoc_stock_maximo,0) from STOCK where stoc_producto = @articulo and stoc_deposito = @deposito
	if @stock <= @maximo AND @maximo != 0
		return 'OCUPACION DEL DEPOSITO '+@deposito +': '+ STR(@stock / @maximo * 100, 5,2) + '%'
	return 'DEPOSITO COMPLETO'
END
GO

select stoc_producto, stoc_deposito, stoc_cantidad, stoc_stock_maximo, dbo.ej1(stoc_producto, stoc_deposito) from STOCK
GO
/*2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha*/

ALTER FUNCTION EJ2 (@articulo char(8), @fecha smalldatetime)
RETURNS numeric(12,2)
BEGIN 
	RETURN isnull((select sum(stoc_cantidad) from STOCK where stoc_producto=@articulo),0) +

	isnull((select sum(item_cantidad) from item_factura join factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
	where fact_fecha >= @fecha and item_producto = @articulo),0)
END
GO

select item_producto, dbo.EJ2(item_producto, '10/01/2011') from Item_Factura
where item_producto = 00001121
group by item_producto

select sum(stoc_cantidad) from STOCK where stoc_producto = '00001121'
select sum(item_cantidad) from item_factura join factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
	where fact_fecha >= '10/01/2011'AND item_producto = '00001121'
GO
/* 3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.
*/

CREATE PROCEDURE ej3
@cantJefes INT OUTPUT 
AS
BEGIN
	 SET @cantJefes  = (select count(*) from Empleado where empl_jefe is null)
	 if (@cantJefes > 1)
	 BEGIN
		UPDATE Empleado
		SET empl_jefe = (SELECT TOP 1 empl_codigo from Empleado WHERE empl_jefe IS NULL ORDER BY empl_salario DESC, empl_ingreso ASC)
		WHERE empl_jefe is null and empl_codigo NOT IN (SELECT TOP 1 empl_codigo from Empleado WHERE empl_jefe IS NULL ORDER BY empl_salario DESC, empl_ingreso ASC) -- le asigna como jefe el gerente gral, a todos los empleados que tienen como jefe NULL y no son el grente gral
	 END
	 PRINT @cantJefes
END
GO

/* 4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.*/

CREATE PROCEDURE ej4
@mejorVendedor NUMERIC(6) OUTPUT
AS
BEGIN
	UPDATE Empleado
	SET empl_salario = empl_salario + (select sum(fact_total) from Factura where fact_vendedor = empl_codigo and year(fact_fecha) = (select max(year(fact_fecha) from Factura))) * empl_comision
	SET @mejorVendedor = (SELECT TOP 1 FACT_VENDEDOR FROM Factura GROUP BY FACT_VENDEDOR ORDER BY SUM(FACT_TOTAL) DESC)
END
GO

/* 6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.*/





/* 7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.*/

create procedure EJ7 @desde datetime, @hasta datetime
AS
BEGIN
	DECLARE @renglon INT, @producto CHAR(8), @detalle CHAR(50), @precio_prom NUMERIC(12,4), @cantidad NUMERIC(12,2), @ganancia NUMERIC(12,2)
	DECLARE c1 CURSOR FOR
		select prod_codigo, prod_detalle, sum(item_cantidad), avg(item_precio), sum(item_precio*item_cantidad) - sum(item_cantidad) * prod_precio
		from item_factura 
		join factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		join producto on prod_codigo = item_producto
		where fact_fecha >= @desde and fact_fecha <= @hasta
		group by prod_codigo, prod_detalle, prod_precio
	OPEN c1
	FETCH NEXT INTO @producto, @detalle, @cantidad, @precio_prom, @renglon, @ganancia
	select @renglon = 1
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Ventas VALUES (@producto, @detalle, @cantidad, @precio_prom, @ganancia)
		SELECT @renglon = @renglon + 1
		FETCH NEXT INTO @producto, @detalle, @cantidad, @precio_prom, @renglon, @ganancia
	END
	CLOSE c1
	DEALLOCATE c1
	RETURN
END
GO

/* 8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas: 
Código | Detalle | Cantidad | Precio_generado | Precio_facturado */

CREATE PROCEDURE Ej8 
AS
BEGIN
	INSERT diferencias 
		SELECT DISTINCT p1.prod_codigo, prod_detalle, (SELECT COUNT(*) FROM composicion WHERE comp_producto = prod_codigo), (SELECT SUM(comp_cantidad * prod_precio) FROM composicion JOIN producto ON comp_componente = prod_codigo WHERE p1.prod_codigo = comp_producto) ,item_precio -- PRIMERO SELECCIONO TODO LO QUE VA A ENTRAR, DESPUES LO INSERTO. IMPORTANTE PRIMERO TENER TODO LO QUE VOY A INSERTAR Y DESP INSERTAR DE UNA. NO IR BUSCANDO E INSERTANDO DE A UNA FILA.
		FROM item_factura JOIN producto p1 ON p1.prod_codigo = item_producto
		WHERE p1.prod_codigo in (select comp_producto from Composicion) AND item_precio <> (SELECT SUM(comp_cantidad * prod_precio) FROM Composicion join Producto ON prod_codigo = p1.prod_codigo AND comp_componente = prod_codigo)
	RETURN
END
GO

/* 9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.*/

CREATE TRIGGER ej9 ON Item_Factura FOR UPDATE 
AS 
BEGIN
	DECLARE @COMPONENTE CHAR(8), @CANTIDAD DECIMAL(12,2)
	DECLARE cursorComponentes CURSOR FOR SELECT comp_componente, (I.item_cantidad - d.item_cantidad) * comp_cantidad from Composicion
											JOIN inserted I ON comp_producto = I.item_producto JOIN deleted d on comp_producto = d.item_producto
											WHERE I.item_cantidad != d.item_cantidad
	OPEN cursorComponentes
	FETCH NEXT FROM cursorComponentes 
	INTO @COMPONENTE, @CANTIDAD
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @CANTIDAD
		WHERE stoc_producto = @COMPONENTE AND stoc_deposito = (SELECT TOP 1 stoc_deposito from STOCK where stoc_producto = @COMPONENTE ORDER BY stoc_cantidad desc)
		FETCH NEXT FROM cursorComponentes
		INTO @COMPONENTE, @CANTIDAD
	END
	CLOSE cursorComponentes
	DEALLOCATE cursorComponentes
END
GO

/* 10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.*/

CREATE TRIGGER ej10 ON Producto INSTEAD OF DELETE
AS
BEGIN
	IF exists(select * from stock join deleted d on stoc_producto = d.prod_codigo where stoc_cantidad > 0)
		BEGIN 
			RAISERROR('Uno de los articulos que se quiso borrar posee stock', 1, 1)
		END
	DELETE FROM STOCK where stoc_producto IN (SELECT prod_codigo from deleted)
	DELETE FROM Composicion WHERE comp_producto IN (SELECT prod_codigo from deleted)
	DELETE FROM Producto WHERE prod_codigo IN (select prod_codigo from deleted)
END
GO
/* 11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.*/

CREATE FUNCTION EJ11 (@jefe NUMERIC(6))
RETURNS INT
AS
BEGIN
	DECLARE @empleado NUMERIC(6), @cantidad INT
	SELECT @cantidad = 0
	DECLARE c1 CURSOR FOR
		SELECT empl_codigo FROM Empleado where empl_jefe = @jefe
	FETCH NEXT INTO @empleado
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @cantidad = @cantidad + 1 + dbo.EJ11(@empleado)
		FETCH NEXT INTO @empleado
	END
	CLOSE c1
	DEALLOCATE c1
	RETURN @cantidad
END
GO
/* 12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/

CREATE TRIGGER EJ12 ON Composicion FOR INSERT
AS 
BEGIN
	if exists ( SELECT * FROM INSERTED WHERE dbo.ej_f12(comp_producto, comp_componente) = 1)
	ROLLBACK
END
GO

CREATE FUNCTION ej_f12 (@producto CHAR(8), @componente CHAR(8))
RETURNS INT
AS
BEGIN
	DECLARE @comp CHAR(8)
	if @producto = @componente
		RETURN 1
	DECLARE c1 CURSOR FOR 
		SELECT comp_componente from Composicion WHERE comp_producto = @componente
	OPEN c1
	FETCH c1 INTO @comp
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF dbo.EJ_12F(@producto, @comp) = 1
			RETURN 1
		FETCH c1 INTO @comp
	END
	CLOSE c1
	DEALLOCATE c1
	RETURN 0
END
GO

/* 13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías*/

CREATE TRIGGER EJ13 ON Empleado FOR DELETE, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM INSERTED) = 0
		IF EXISTS(SELECT 1 FROM DELETED d WHERE (SELECT empl_salario from Empleado WHERE d.empl_jefe = empl_jefe) > dbo.EJ13F(d.empl_jefe) * 0.2)
		ROLLBACK
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM INSERTED i WHERE (SELECT empl_salario from Empleado WHERE i.empl_jefe = empl_jefe) > dbo.EJ13F(i.empl_jefe) * 0.2)
		ROLLBACK
	END
END
GO

ALTER FUNCTION EJ13F (@jefe NUMERIC(6))
RETURNS INT
AS
BEGIN
	DECLARE @empleado NUMERIC(6), @salarios NUMERIC(12,2)
	SELECT @salarios = 0
	DECLARE c1 CURSOR FOR
		SELECT empl_codigo FROM Empleado where empl_jefe = @jefe
	OPEN c1
	FETCH c1 INTO @empleado
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @salarios = @salarios + (SELECT empl_salario FROM Empleado WHERE empl_codigo = @empleado) + dbo.EJ13F(@empleado)
		FETCH c1 INTO @empleado
	END
	CLOSE c1
	DEALLOCATE c1
	RETURN @salarios
END
GO

/* 14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes*/

CREATE TRIGGER EJ_14 ON Item_Factura FOR INSERT
AS
BEGIN
	
END
GO


CREATE FUNCTION sumaDeComponentes (@producto CHAR(8))
RETURNS NUMERIC(12,4)
AS
BEGIN
	DECLARE @suma NUMERIC(12,4)
	DECLARE @comp CHAR(8)
	DECLARE c1 CURSOR FOR 
		SELECT comp_componente from Composicion WHERE comp_producto = @producto
	OPEN c1
	FETCH c1 INTO @comp
	WHILE @@FETCH_STATUS = 0
	SELECT @suma = @suma + (SELECT SUM(comp_cantidad * prod_precio) FROM Composicion JOIN Producto ON comp_componente = prod_codigo WHERE comp_producto = @producto )
	BEGIN
		SELECT @suma =  @suma + dbo.sumaDeComponentes(@comp)
		FETCH c1 INTO @comp
	END
	CLOSE c1
	DEALLOCATE c1
	RETURN @suma
END
GO

/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*/



ALTER FUNCTION EJ15F (@producto CHAR(8))
RETURNS numeric(12,4)
AS
BEGIN
    IF (SELECT COUNT(*) FROM Composicion WHERE comp_producto = @producto) > 0 
    BEGIN 
        declare @suma numeric(12,4)
        declare @comp char(8)
        DECLARE cursorComponentes CURSOR FOR SELECT comp_componente FROM Composicion WHERE comp_producto = @producto
        OPEN cursorComponentes
        FETCH cursorComponentes INTO @comp
        SELECT @suma = (SELECT isnull(SUM(comp_cantidad * prod_precio),0) FROM Composicion JOIN Producto ON comp_componente = prod_codigo WHERE comp_producto = @producto)
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @suma = @suma + dbo.EJ15F(@comp)
            FETCH cursorComponentes INTO @comp
        END
        CLOSE cursorComponentes
        DEALLOCATE cursorComponentes
    END
    ELSE
        SELECT @suma = prod_precio FROM Producto WHERE prod_codigo = @producto
    
return @suma
END
GO

select prod_codigo, prod_detalle, prod_precio, dbo.EJ15F(prod_codigo) 
from Producto
where prod_precio <> dbo.EJ15F(prod_codigo)
GO
/*16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.*/


-- TODO: TERMINAR POR MI CUENTA
CREATE TRIGGER EJ16 ON ITEM_FACTURA FOR INSERT
AS
BEGIN
		DECLARE @prod CHAR(8)
		DECLARE @cant DECIMAL(12,2)
		DECLARE c1 CURSOR FOR (SELECT item_producto, item_cantidad FROM inserted)
		FETCH c1 INTO @prod, @cant
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			EXEC dbo.actualizarStock @prod, @cant;
			FETCH c1 INTO @prod, @cant
		END
		CLOSE C1
		DEALLOCATE C1
END
GO

CREATE PROCEDURE actualizarStock
	@prod char(8), 
	@cant DECIMAL(12,2)
AS
BEGIN
	declare 
		@stockActual decimal(12,2),
		@deposito char(2);
		DECLARE c_depositos CURSOR FOR
			SELECT stoc_deposito, stoc_cantidad
			FROM STOCK
			WHERE stoc_producto = @prod
			ORDER BY stoc_cantidad DESC;
	OPEN C_DEPOSITOS
	FETCH C_depositos INTO @deposito, @stockActual
END
GO
/*17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock*/


-- SALVO QUE ACLAREN DE USAR UN INSTEAD OF, SIEMPRE ES MEJOR NO USARLO.
CREATE TRIGGER EJ17 ON STOCK AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS(SELECT count(*) FROM inserted WHERE stoc_cantidad < stoc_punto_reposicion OR stoc_cantidad > stoc_stock_maximo)
	BEGIN
		PRINT 'SUPERA LA REGLA DE STOCK'
		ROLLBACK
	END
END
GO

/*18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/

CREATE TRIGGER EJ18 ON FACTURA AFTER INSERT
AS
BEGIN
	IF EXISTS(
	SELECT fact_cliente 
	FROM inserted JOIN Cliente ON clie_codigo = fact_cliente
	WHERE clie_limite_credito < (SELECT sum(i.fact_total) + (SELECT sum(fact_total) from factura WHERE clie_codigo = i.fact_cliente AND year(fact_fecha) = year(i.fact_fecha) AND month(fact_fecha) = month(i.fact_fecha)) from inserted i where i.fact_cliente = clie_codigo)	
				)
				BEGIN
				PRINT 'SUPERA EL LIMITE DE CREDITO'
				ROLLBACK 
				END
END
GO
/*19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.*/

CREATE TRIGGER EJ19 ON EMPLEADO FOR INSERT, UPDATE, DELETE
AS
BEGIN 
	IF EXISTS(SELECT 1 FROM INSERTED WHERE empl_codigo in (SELECT empl_jefe from Empleado) AND (DATEDIFF(YEAR,empl_ingreso, GETDATE()) < 5 OR dbo.EJ11(empl_codigo) > (SELECT COUNT(*)/2 from Empleado)))
	BEGIN
		PRINT 'NO CUMPLE LA REGLA'
		ROLLBACK
	END
END
GO
/*20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
*/

-- FALOPA EL CÁLCULO DE LA COMISION, ME GUIÉ POR LO QUE HIZO QUIQUE

CREATE TRIGGER EJ20 ON FACTURA FOR INSERT, DELETE
AS
BEGIN
	DECLARE @empleado NUMERIC(6)
	DECLARE @comision NUMERIC(5,2)
	DECLARE @anio NUMERIC(4)
	DECLARE @mes NUMERIC(2)
	DECLARE @montoAnterior NUMERIC(12,2)
	IF (SELECT COUNT(*) FROM INSERTED) > 0
	BEGIN
		DECLARE C1 CURSOR FOR 
			SELECT fact_vendedor, year(fact_fecha), MONTH(fact_fecha), SUM(fact_total) 
			FROM INSERTED
			GROUP BY fact_vendedor, year(fact_fecha), MONTH(fact_fecha)
	END
	ELSE 
	BEGIN
		DECLARE C1 CURSOR FOR 
			SELECT fact_vendedor, year(fact_fecha), MONTH(fact_fecha), SUM(fact_total) 
			FROM DELETED
			GROUP BY fact_vendedor, year(fact_fecha), MONTH(fact_fecha)
	END
	OPEN C1
	FETCH NEXT FROM C1 INTO @empleado, @anio, @mes, @total
	WHILE @@FETCH_STATUS = 0
	BEGIN
			IF (SELECT COUNT(DISTINCT item_producto) 
				FROM Item_Factura 
				JOIN Factura ON item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
				WHERE YEAR(fact_fecha) = @anio AND MONTH(fact_fecha) = @mes AND fact_vendedor = @empleado
				) >= 50
				SET @comision = 0.08
			ELSE
				SET @comision = 0.5
		UPDATE Empleado
			SET empl_comision = @montoAnterior + (SELECT SUM(fact_total)
													FROM Factura 
													WHERE YEAR(fact_fecha) = @anio AND MONTH(fact_fecha) = @mes AND fact_vendedor = @empleado
												) * @comision
			WHERE empl_codigo = @empleado
		FETCH NEXT FROM C1 INTO @empleado, @anio, @mes, @total
	END
END
GO

/*21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla*/

CREATE TRIGGER EJ21 ON Item_Factura FOR INSERT
AS
BEGIN
	IF EXISTS(SELECT * 
				FROM inserted
				JOIN Producto ON item_producto = prod_codigo
				GROUP BY item_numero, item_tipo, item_sucursal
				HAVING COUNT(DISTINCT prod_familia) > 1
				)
	BEGIN
		DELETE FROM Item_Factura 
			WHERE item_numero + item_tipo + item_sucursal IN (SELECT item_numero + item_tipo + item_sucursal FROM inserted)
		DELETE FROM Factura
			WHERE fact_numero + fact_tipo + fact_sucursal IN (SELECT item_numero + item_tipo + item_sucursal FROM inserted)
		RAISERROR('NO SE PUEDEN FACTURAR PRODUCTOS DE DISTINTAS FAMILIAS')
	END
END
GO
/*22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.*/

CREATE PROCEDURE EJ22
AS
BEGIN
	DECLARE C1 CURSOR FOR
		SELECT rubr_id, COUNT(prod_codigo) FROM Rubro JOIN Producto ON rubr_id = prod_rubro GROUP BY rubr_id ORDER BY rubr_id
	DECLARE @rubro CHAR(4)
	DECLARE @cant INT
	OPEN C1
	FETCH C1 INTO @rubro, @cant
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @cant > 20
		BEGIN
			EXEC dbo.RECATEGORIZAR @rubro, @cant
		END
		FETCH C1 INTO @rubro
	END
	CLOSE C1
	DEALLOCATE C1
END
GO

CREATE PROCEDURE RECATEGORIZAR (@rubro CHAR(4), @cant INT)
AS
BEGIN
	DECLARE @producto CHAR(8)
	DECLARE @nuevoRubro CHAR(4)
	DECLARE CProductos CURSOR FOR
		SELECT prod_codigo FROM Producto WHERE prod_rubro = @rubro
	OPEN CProductos
	FETCH CProductos INTO @producto
	WHILE @@FETCH_STATUS = 0 AND @cant > 20
	BEGIN
		SET @nuevoRubro = (SELECT TOP 1 rubr_id FROM Producto JOIN Rubro ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT(*)<20 ORDER BY COUNT(*))
		IF @nuevoRubro IS NULL
		BEGIN
			IF NOT EXISTS (SELECT rubr_detalle FROM Rubro WHERE rubr_detalle = 'RUBRO REASIGNADO')
				INSERT INTO RUBRO (rubr_detalle) VALUES('RUBRO REASIGNADO')	
			SET @nuevoRubro = (SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'RUBRO REASIGNADO')
		END
		UPDATE Producto
			SET prod_rubro = @nuevoRubro
			WHERE prod_codigo = @producto
		FETCH CProductos INTO @producto
	END
END
GO
/*23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.*/

CREATE TRIGGER EJ23 ON Item_Factura FOR INSERT
AS
BEGIN
	IF EXISTS(SELECT COUNT(DISTINCT item_producto) 
		FROM inserted 
		JOIN Composicion ON item_producto = comp_producto
		GROUP BY item_numero, item_tipo, item_sucursal
		HAVING COUNT(DISTINCT item_producto) > 2)
	BEGIN
		DELETE FROM Item_Factura
			WHERE item_numero + item_tipo + item_sucursal IN (SELECT item_numero + item_tipo + item_sucursal 
																FROM Item_Factura 
																JOIN Composicion ON item_producto = comp_producto
																GROUP BY item_numero + item_tipo + item_sucursal
																HAVING COUNT(DISTINCT item_producto) > 2) 
		DELETE FROM Factura
			WHERE fact_numero + fact_tipo + fact_sucursal IN (SELECT item_numero + item_tipo + item_sucursal FROM inserted GROUP BY item_numero + item_tipo + item_sucursal)
	END
END
GO

/*24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.*/

CREATE PROCEDURE EJ24
AS
BEGIN
	DECLARE @empleado NUMERIC(6), @deposito CHAR(2), @zonaDepo CHAR(3), @zonaEmpl CHAR(3)
	DECLARE C1 CURSOR FOR
		SELECT depo_encargado, depo_codigo, depo_zona, depa_zona
		FROM Empleado 
		JOIN Departamento ON empl_departamento = depa_codigo
		JOIN DEPOSITO ON depo_encargado = empl_codigo
		WHERE depo_zona <> depa_zona
	OPEN C1
	FETCH C1 INTO @empleado, @deposito, @zonaDepo, @zonaEmpl
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE DEPOSITO
			SET depo_encargado = (SELECT TOP 1 empl_codigo	
									FROM Empleado 
									JOIN Departamento ON empl_departamento = depa_codigo
									LEFT JOIN DEPOSITO ON empl_codigo = depo_encargado
									WHERE depa_zona = @zonaDepo
									GROUP BY empl_codigo
									ORDER BY COUNT(DISTINCT depo_codigo) 
									)
			WHERE depo_codigo = @deposito
		FETCH C1 INTO @empleado, @deposito, @zonaDepo, @zonaEmpl
	END
	CLOSE C1
	DEALLOCATE C1
END
GO

/*25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.*/

CREATE TRIGGER EJ25 ON Composicion FOR INSERT, UPDATE
AS
BEGIN
	IF EXISTS(SELECT * 
				FROM inserted c1 
				JOIN Composicion c2 ON c1.comp_producto = c2.comp_componente AND c2.comp_producto = c1.comp_componente 
				WHERE c1.comp_producto <> c2.comp_producto)
	ROLLBACK TRANSACTION
END
GO

/*26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla*/

CREATE TRIGGER EJ26 ON Item_Factura FOR INSERT
AS
BEGIN
	IF EXISTS(SELECT item_producto 
				FROM inserted
				WHERE item_producto IN (SELECT comp_componente FROM Composicion))
	BEGIN
		DELETE FROM Item_Factura
			WHERE item_numero + item_tipo + item_sucursal IN (SELECT I.item_numero + I.item_tipo + I.item_sucursal 
																FROM inserted i
																GROUP BY I.item_numero + I.item_tipo + I.item_sucursal)
		DELETE FROM Factura
			WHERE fact_numero + fact_tipo + fact_sucursal IN (SELECT I.item_numero + I.item_tipo + I.item_sucursal 
																FROM inserted i
																GROUP BY I.item_numero + I.item_tipo + I.item_sucursal)
		RAISERROR('NO SE PUEDE CREAR UNA FACTURA CON ITEMS COMPUESTOS, BORRANDO ITEMS Y FACTURA', 1,1)
	END
END


/*27. Se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.*/

CREATE PROCEDURE EJ27 
AS
BEGIN
	DECLARE C1 CURSOR FOR 
		SELECT depo_codigo FROM DEPOSITO
	DECLARE @depo CHAR(2)
	OPEN C1
	FETCH NEXT FROM C1 INTO @depo
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE DEPOSITO
			SET depo_encargado = (SELECT TOP 1 empl_codigo 
									FROM Empleado 
									LEFT JOIN DEPOSITO ON depo_encargado = empl_codigo
									WHERE empl_codigo NOT IN (SELECT j.empl_jefe FROM Empleado j GROUP BY j.empl_jefe)
									AND empl_codigo NOT IN (SELECT fact_vendedor FROM Factura GROUP BY fact_vendedor) 
									GROUP BY empl_codigo
									ORDER BY COUNT(*) 
									)
			WHERE depo_codigo = @depo
		FETCH NEXT FROM C1 INTO @depo
	END
	CLOSE C1
	DEALLOCATE C1
END

