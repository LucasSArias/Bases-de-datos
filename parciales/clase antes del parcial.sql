/*3. Mostrar dos filas con los 2 empleados del mes: Estos son:
c) El empleado que en el último año que haya ventas (en el cual se ejecuta la query) vendió
más en dinero (fact_total)
d) El segundo empleado del año, es aquel que en el mismo año (en el cual se ejecuta la query)
tiene más facturas emitidas
Se deberá mostrar Apellido y nombre del empleado en una sola columna y para el primero un
string que diga (Mejor Facturación y para el Segundo Vendió Más Facturas).
No se permiten sub select en el FROM.*/


SELECT TOP 1 RTRIM(empl_apellido) + ' ' + RTRIM(empl_nombre), 'MEJOR FACTURACION'
FROM Factura
JOIN Empleado ON fact_vendedor = empl_codigo
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(f.fact_fecha)) FROM Factura f) AND empl_codigo IN (SELECT TOP 1 fact_vendedor FROM Factura GROUP BY fact_vendedor ORDER BY SUM(fact_total) DESC)
GROUP BY empl_apellido, empl_nombre

UNION ALL

SELECT TOP 1 RTRIM(empl_apellido) + ' ' + RTRIM(empl_nombre), 'VENDIO MAS FACTURAS'
FROM Factura
JOIN Empleado ON fact_vendedor = empl_codigo
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(f.fact_fecha)) FROM Factura f) AND empl_codigo IN (SELECT TOP 1 fact_vendedor FROM Factura GROUP BY fact_vendedor ORDER BY COUNT(*) DESC)
GROUP BY empl_apellido, empl_nombre

/*Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor
cantidad de días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de
una unidad en el día, el sistema de ventas on line está habilitado 24-7 por lo que se deben
evaluar todos los días incluyendo domingos y feriados.*/

-- ESTA EN EL AULA VIRTUAL
