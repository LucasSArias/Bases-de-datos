/* 1. Realizar una consulta que muestre, para los clientes que compraron 
únicamente en años pares, la siguiente información: 
    - El numero de fila
    - el codigo de cliente
    - el nombre del producto más comprado por el cliente
    - la cantidad total comprada por el cliente en el último año --> cantidad del producto mas comprado?

El resultado debe estar ordenado en función de la cantidad máxima comprada por cliente
de mayor a menor*/ 

SELECT f.fact_cliente, 
(SELECT TOP 1 prod_detalle 
    FROM Factura 
    JOIN Item_Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal 
    JOIN Producto ON prod_codigo = item_producto
    WHERE fact_cliente = f.fact_cliente
    GROUP BY prod_detalle
    ORDER BY count(item_cantidad) DESC
) producto_mas_comprado, 
(SELECT SUM(item_cantidad) 
    FROM Factura 
    JOIN Item_Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal 
    WHERE fact_cliente = f.fact_cliente AND YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
    )
FROM Factura f
JOIN Item_Factura ON item_numero + item_tipo + item_sucursal = f.fact_numero + f.fact_tipo + f.fact_sucursal
JOIN Producto ON item_producto = prod_codigo
WHERE f.fact_cliente NOT IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha)%2 <> 0 GROUP BY fact_cliente)
GROUP BY fact_cliente
ORDER BY 3 DESC


/*
Implementar un sistema de auditoria para registrar cada operacion realizada en la tabla 
cliente. El sistema debera almacenar, como minimo, los valores(campos afectados), el tipo 
de operacion a realizar, y la fecha y hora de ejecucion. SOlo se permitiran operaciones individuales
(no masivas) sobre los registros, pero el intento de realizar operaciones masivas deberá ser registrado
en el sistema de auditoria
*/

CREATE TABLE Auditoria (
    audi_operacion CHAR(50),
    audi_fecha DATETIME,
    audi_codigo CHAR(6) NOT NULL,
    audi_razon_social CHAR(100),
    audi_telefono CHAR(100),
    audi_domicilio CHAR(100),
    audi_limite_credito DECIMAL(12,2),
    audi_vendedor CHAR(6)
)
GO


CREATE TRIGGER auditar ON Auditoria FOR INSERT, DELETE -- tambien deberia ser para el update pero big paja
AS
BEGIN
    DECLARE @fecha DATETIME
    DECLARE @operacion CHAR(20)
    SET @fecha = GETDATE()
    IF (SELECT COUNT(*) FROM inserted) > 1 OR (SELECT COUNT(*) FROM deleted) > 1
    BEGIN
        SET @operacion = 'MULTIPLES OPERACIONES'
        INSERT INTO Auditoria (
        audi_operacion,
        audi_fecha
        ) VALUES (@operacion, @fecha)
        ROLLBACK TRANSACTION
    END
    ELSE 
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        SET @operacion = 'INSERT'
        INSERT INTO Auditoria (
        audi_operacion,
        audi_fecha,
        audi_codigo,
        audi_razon_social,
        audi_telefono,
        audi_domicilio,
        audi_limite_credito,
        audi_vendedor
        ) (SELECT @operacion, @fecha, audi_codigo, audi_razon_social, audi_telefono, audi_domicilio, audi_limite_credito, audi_vendedor FROM inserted)
    END
    ELSE
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        SET @operacion = 'DELETE'
        INSERT INTO Auditoria (
        audi_operacion,
        audi_fecha,
        audi_codigo,
        audi_razon_social,
        audi_telefono,
        audi_domicilio,
        audi_limite_credito,
        audi_vendedor
        ) (SELECT @operacion, @fecha, audi_codigo, audi_razon_social, audi_telefono, audi_domicilio, audi_limite_credito, audi_vendedor FROM inserted)
    END

END

