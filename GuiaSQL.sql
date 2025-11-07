/* 1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.*/

select clie_codigo, clie_razon_social 
from Cliente
where clie_limite_credito > 1000

/* 2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/

select prod_codigo, prod_detalle, sum(item_cantidad)
from Producto join Item_Factura ON prod_codigo = item_producto JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
order by sum(item_cantidad) desc

/* 3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.*/

select prod_codigo, prod_detalle, sum(isnull(stoc_cantidad, 0))
from producto left join stock on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
order by prod_detalle

/* 4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.*/

select prod_codigo, prod_detalle, count(comp_componente)
from Producto left join Composicion on prod_codigo = comp_producto
where prod_codigo in (select stoc_producto
					from stock
					group by stoc_producto
					having avg(stoc_cantidad) > 100)
group by prod_codigo, prod_detalle

/* 5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.*/

select prod_codigo, prod_detalle, sum(item_cantidad) 'VENTAS 2012'
from producto join Item_Factura on prod_codigo = item_producto
join factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
having sum(item_cantidad) > (select sum(item_cantidad) from Item_Factura join factura on 
								fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
								where year(fact_fecha) = 2011 and item_producto = prod_codigo)

/* 6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/


select rubr_id, rubr_detalle, count(distinct stoc_producto) cantidadProductos, sum(isnull(stoc_cantidad,0)) stockProductos 
from Rubro left join Producto on rubr_id = prod_rubro
left join STOCK on prod_codigo = stoc_producto
where prod_codigo in (select stoc_producto from stock group by stoc_producto having sum(stoc_cantidad) > (select stoc_cantidad from stock where stoc_producto = '00000000' AND stoc_deposito = '00'))
group by rubr_id, rubr_detalle
order by 1


-- VUELVO A RESOLVER LOS PRIMEROS 6 EJERCICIOS POR MI CUENTA

/* 1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.*/

select clie_codigo, clie_razon_social
from Cliente
where clie_limite_credito >= 1000
order by 1

/* 2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/

select prod_codigo, prod_detalle, sum(item_cantidad) cantidad_vendida, year(fact_fecha) año
from Producto join Item_Factura on item_producto = prod_codigo join Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle, year(fact_fecha)
order by sum(item_cantidad) desc

/* 3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.*/

select prod_codigo, prod_detalle, isnull(sum(stoc_cantidad), 0) stock_total
from Producto left join STOCK on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
order by prod_detalle

/* 4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.*/

select prod_codigo, prod_detalle, count(comp_componente)
from Producto left join Composicion on prod_codigo = comp_producto	
where prod_codigo in (select stoc_producto
					from stock
					group by stoc_producto
					having avg(stoc_cantidad) > 100
						)
group by prod_codigo, prod_detalle

/* 5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.*/

select prod_codigo, prod_detalle, sum(item_cantidad)
from Producto join Item_Factura on prod_codigo = item_producto join Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle

/* 6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/

select rubr_id, rubr_detalle, count(prod_rubro) cant_articulos, sum(stoc_cantidad)
from Rubro left join Producto on rubr_id = prod_rubro
join STOCK on prod_codigo = stoc_producto AND prod_codigo in (select prod_codigo from STOCK where stoc_cantidad > ( select stoc_cantidad from STOCK where stoc_producto = '00000000' AND stoc_deposito = 00 ))
group by rubr_id, rubr_detalle



/* 7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.*/

select prod_codigo, prod_detalle, max(item_precio) mayor_precio, min(item_precio) menor_precio, convert(numeric(5,2), max(item_precio) * 100 / min(item_precio) - 100) diferencia
from Producto join Item_Factura on prod_codigo = item_producto
where prod_codigo in (select stoc_producto from STOCK where stoc_cantidad > 0)
group by prod_codigo, prod_detalle
order by 5 desc

/* 8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.
*/

select prod_detalle, MAX(stoc_cantidad) stoc_maximo, min(stoc_cantidad)
from Producto join STOCK on prod_codigo = stoc_producto join DEPOSITO on stoc_deposito = stoc_producto
where stoc_cantidad > 0
group by prod_detalle
order by 1

/* 9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.*/

select empl_jefe, empl_codigo, empl_nombre, count(*) depositos_en_conjunto
from Empleado join DEPOSITO on empl_codigo = depo_encargado or empl_jefe = depo_encargado
group by empl_jefe, empl_codigo, empl_nombre


/* 10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.*/

select prod_codigo, (
		select top 1 fact_cliente
		from Factura join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		where item_producto = prod_codigo
		group by fact_cliente
		order by sum (item_cantidad) desc
	) as cliente_mayor_compra
from Producto
where prod_codigo in (
		select top 10 item_producto from Item_Factura
		group by item_producto	
		order by sum(item_cantidad)
		) or
		prod_codigo in (
		select top 10 item_producto from Item_Factura
		group by item_producto	
		order by sum(item_cantidad) desc
	)


/* 11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.*/

-- sin impuestos: total - total sin impuestos

select fami_detalle, count(distinct(item_producto)) productos_vendidos, sum(item_precio* item_cantidad) monto_recaudado
from Familia join Producto on fami_id = prod_familia join Item_Factura on prod_codigo = item_producto
group by fami_detalle
having fami_detalle in (
		select fami_detalle
		from Familia join Producto on fami_id = prod_familia join Item_Factura on prod_codigo = item_producto join Factura on fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal
		where year(fact_fecha) = 2012
		group by fami_detalle
		having sum(item_cantidad * item_precio) > 20000 
		) 
order by 3 desc

/* 12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.*/


select prod_detalle, count(distinct(fact_cliente)), avg(item_precio) precio_promedio,
(select count(distinct(stoc_deposito)) from STOCK join Producto on stoc_producto = prod_codigo where stoc_cantidad > 0) cant_depositos_con_stock,
(select sum(stoc_cantidad) from STOCK where stoc_producto = prod_codigo)
from Producto 
join Item_Factura on prod_codigo = item_producto 
join Factura on fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal 
where prod_codigo in (	select prod_codigo from Producto 
						join Item_Factura on prod_codigo = item_producto 
						join Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
						where year(fact_fecha) = 2012
						
)
group by prod_detalle, prod_codigo
order by 2 desc

/* 13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen. */
-- EJERCICIO BORONGA

select combo.prod_detalle as combo, combo.prod_precio as precio_combo, sum(prodComponente.prod_precio * c.comp_cantidad) as precio_comprando_separado, count(c.comp_componente) as cant_componentes
from Producto combo join Composicion c on combo.prod_codigo = c.comp_producto join Producto prodComponente on prodComponente.prod_codigo = c.comp_componente
group by combo.prod_detalle, combo.prod_precio
having count(*) > 1
order by cant_componentes desc

/*14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:

Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año

Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año. No se deberán visualizar NULLs en ninguna columna*/

select c.clie_codigo,
count(distinct(fact_tipo + fact_sucursal + fact_numero)) as cant_compras,
isnull(avg(fact_total),0) as compra_promedio, 
isnull(max(fact_total),0) compra_max,
count(distinct(item_producto)) as cant_prods_distintos
from Cliente c left join Factura on clie_codigo = fact_cliente and year(fact_fecha) = (select max(year(fact_fecha)) from Factura ) left join Item_Factura on fact_tipo + fact_numero + fact_sucursal = item_tipo + item_numero + item_sucursal
group by clie_codigo
order by count(fact_cliente) desc

/*15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1			PROD2	DETALLE2				VECES
1731 MARLBORO KS		1718	PHILIPS MORRIS KS		507
1718 PHILIPS MORRIS KS	1705	PHILIPS MORRIS BOX 10	562*/

select p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, count(*) as veces_vendidas
from Item_Factura i1 join Item_Factura i2 on i1.item_tipo = i2.item_tipo
and i1.item_numero = i2.item_numero
and i1.item_sucursal = i2.item_sucursal
and i1.item_producto > i2.item_producto -- Si usara != aparecerian duplicados los pares
join Factura on fact_tipo + fact_numero + fact_sucursal = i1.item_tipo + i1.item_numero + i1.item_sucursal -- Usar i1 o i2 es indistinto porque ambos items pertenecen a la misma fact
join Producto p1 on p1.prod_codigo = i1.item_producto
join Producto p2 on p2.prod_codigo = i2.item_producto
group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
having count(*) > 500
order by 5 

/*16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas compras
son inferiores a 1/3 del monto de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.*/


select clie_razon_social,
sum(isnull(item_cantidad,0)) as total_cant_items_comprados, 
isnull((select top 1 item_producto 
	from Item_Factura join Factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero 
	where clie_codigo = fact_cliente and year (fact_fecha) = 2012 
	group by item_producto
	order by sum(item_cantidad) desc, item_producto),'No tiene') as producto_mas_comprado
from Cliente join Factura on clie_codigo = fact_cliente left join Item_Factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero and year(fact_fecha) = 2012
group by clie_razon_social, clie_codigo
having isnull((select sum(fact_total-fact_total_impuestos) from factura where fact_cliente = clie_codigo),0) < (select top 1 sum(item_precio*item_cantidad) from Item_Factura join Factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
							where  year(fact_fecha) = 2012
							group by item_producto
							order by sum(item_cantidad) desc) / 3
order by 2 desc


/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto. */

-- TODO: CHEQUEAR CON PEDRO SI LA COLUMNA ventasAnioAnterior DA TODO NULL
 
SELECT CONVERT(CHAR(6), fact_fecha, 112) as periodo, prod_codigo, prod_detalle, SUM(item_cantidad) as ventasDelPeriodo,
(	SELECT SUM(i.item_cantidad) 
	FROM Item_Factura i 
	JOIN Factura f ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
	WHERE i.item_producto = item_producto AND YEAR(f.fact_fecha) = YEAR(fact_fecha) - 1 AND MONTH(f.fact_fecha) = MONTH(fact_fecha)
) as ventasAnioAnterior
, COUNT(DISTINCT(fact_tipo + fact_numero + fact_sucursal)) as cantFacturas
FROM Producto 
JOIN Item_Factura ON prod_codigo = item_producto 
JOIN Factura ON item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
GROUP BY CONVERT(CHAR(6), fact_fecha, 112), prod_codigo, prod_detalle
ORDER BY 1, 2

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/


SELECT r.rubr_detalle, 
ISNULL(SUM(item_cantidad * item_precio), 0) ventas, 
ISNULL((	
		SELECT TOP 1 prod_codigo 
		FROM Producto 
		JOIN Item_Factura ON prod_codigo = item_producto
		WHERE prod_rubro = r.rubr_id
		GROUP BY prod_codigo
		ORDER BY COUNT(item_tipo + item_sucursal + item_numero) DESC
), 'NO VENDIO' )AS PROD1,
ISNULL((
        SELECT prod_codigo
        FROM Producto
        JOIN Item_Factura ON prod_codigo = item_producto
        WHERE prod_rubro = r.rubr_id
        GROUP BY prod_codigo
        ORDER BY COUNT(item_tipo + item_sucursal + item_numero) DESC
        OFFSET 1 ROWS -- Saltea el primer producto, espero que quique no se ponga policia con esto
        FETCH NEXT 1 ROWS ONLY -- Toma el segundo
), 'NO VENDIO') AS PROD2,
ISNULL((
		SELECT TOP 1 clie_codigo 
		FROM Cliente 
		JOIN Factura f ON f.fact_cliente = clie_codigo
		JOIN Item_Factura i ON i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero AND f.fact_fecha >= (SELECT MAX(fact_fecha)-30 FROM Factura)
		JOIN Producto p ON i.item_producto = p.prod_codigo
		WHERE p.prod_rubro = r.rubr_id 
		GROUP BY clie_codigo
		ORDER BY SUM(i.item_cantidad) DESC
), 'NADIE') as mejorComprador
FROM Rubro r
JOIN Producto ON prod_rubro = r.rubr_id
LEFT JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY r.rubr_detalle, r.rubr_id
ORDER BY COUNT(DISTINCT(item_producto))

/* 19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
 Codigo de producto
 Detalle del producto
 Codigo de la familia del producto
 Detalle de la familia actual del producto
 Codigo de la familia sugerido para el producto
 Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

SELECT p1.prod_codigo, p1.prod_detalle, fami_id, fami_detalle as id_familia_actual, 
(	SELECT TOP 1 p2.prod_familia
	FROM Producto p2 
	WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
	GROUP BY p2.prod_familia
	ORDER BY COUNT(*) DESC
) id_nueva_familia,
(
	SELECT TOP 1 f.fami_detalle 
	FROM Familia f
	JOIN Producto p2 ON f.fami_id = p2.prod_familia
	WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
	GROUP BY f.fami_detalle
	ORDER BY COUNT(*) DESC
) detalle_fami_sugerida

FROM Producto p1
JOIN Familia ON prod_familia = fami_id
GROUP BY p1.prod_codigo, p1.prod_detalle, fami_id, fami_detalle
HAVING fami_id <> (	SELECT TOP 1 p2.prod_familia
	FROM Producto p2 
	WHERE LEFT(p2.prod_detalle, 5) = LEFT(p1.prod_detalle, 5)
	GROUP BY p2.prod_familia
	ORDER BY COUNT(*) DESC
)
ORDER BY 2 ASC

/* 20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año. */

SELECT TOP 3 empl_codigo, empl_nombre, empl_apellido, YEAR(empl_ingreso) anio_ingreso, 
( SELECT
	CASE WHEN COUNT(*) >= 50
	THEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = empl_codigo AND fact_total > 100 AND YEAR(fact_fecha) = 2011)
	ELSE (SELECT COUNT(*)/2 FROM Factura JOIN Empleado emp ON fact_vendedor = emp.empl_codigo WHERE emp.empl_jefe = empl_codigo AND YEAR(fact_fecha) = 2011 )
	END
	FROM Factura f1 
	WHERE f1.fact_vendedor = empl_codigo
) puntaje_2011,
( SELECT
	CASE WHEN COUNT(*) >= 50
	THEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = empl_codigo AND fact_total > 100 AND YEAR(fact_fecha) = 2012)
	ELSE (SELECT COUNT(*)/2 FROM Factura JOIN Empleado emp ON fact_vendedor = emp.empl_codigo WHERE emp.empl_jefe = empl_codigo AND YEAR(fact_fecha) = 2012 )
	END
	FROM Factura f1 
	WHERE f1.fact_vendedor = empl_codigo
) puntaje_2012
FROM Empleado
ORDER BY 6 DESC

/* 21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año
*/


SELECT YEAR(f.fact_fecha), 
(	SELECT COUNT(DISTINCT f1.fact_cliente)
    FROM Factura f1 
	WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
	AND f1.fact_total - f1.fact_total_impuestos - (SELECT SUM(item_cantidad * item_precio) 
														FROM Item_Factura 
														WHERE item_tipo = f1.fact_tipo AND item_sucursal = f1.fact_sucursal AND item_numero = f1.fact_numero) > 1 

) clientes_mal_facturados,
(	SELECT COUNT(*) 
	FROM Factura f1
	WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
	AND f1.fact_total - f1.fact_total_impuestos - (SELECT SUM(item_cantidad * item_precio) 
														FROM Item_Factura 
														WHERE item_tipo = f1.fact_tipo AND item_sucursal = f1.fact_sucursal AND item_numero = f1.fact_numero) > 1 
) facturas_mal_realizadas
FROM Factura f
GROUP BY YEAR(fact_fecha)


/* 22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.*/

SELECT r.rubr_detalle, DATEPART(QUARTER ,f.fact_fecha) trimestre, COUNT (DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) ventas_del_rubro, COUNT(DISTINCT p.prod_codigo) productos_distintos
FROM Rubro r
JOIN Producto p on p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_sucursal + f.fact_tipo
GROUP BY r.rubr_detalle, DATEPART(QUARTER ,f.fact_fecha)
HAVING COUNT(*) > 100
ORDER BY 1, 3 DESC

/*23. Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente.*/

SELECT 
	YEAR(fact_fecha) año,
	c.comp_producto,
	COUNT(DISTINCT c.comp_componente) cant_productos_componentes,
	COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) ventas_anuales,
	(SELECT TOP 1 f1.fact_cliente 
		FROM Factura f1 
		JOIN Item_Factura i1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
		WHERE i1.item_producto = c.comp_producto
		GROUP BY f1.fact_cliente
		ORDER BY COUNT(*) DESC) mayor_comprador,
	(SUM(i.item_cantidad * i.item_precio) * 100 / (SELECT SUM(f1.fact_total) FROM Factura f1 WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha))) porcentaje_respecto_total
FROM Factura f
JOIN Item_Factura i ON i.item_numero + i.item_tipo + i.item_sucursal = f.fact_numero + f.fact_tipo + f.fact_sucursal
JOIN Composicion c ON c.comp_producto = i.item_producto
GROUP BY YEAR(fact_fecha), c.comp_producto
HAVING c.comp_producto IN (
	SELECT TOP 1 i1.item_producto 
	FROM Item_Factura i1
	JOIN Factura f1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
	WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND i1.item_producto IN (SELECT comp_producto FROM Composicion)
	GROUP BY i1.item_producto
	ORDER BY SUM(i1.item_cantidad) DESC
	)
ORDER BY 4 

/*24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) unidades_facturadas
FROM Factura f 
JOIN Item_Factura i ON i.item_numero + i.item_tipo + i.item_sucursal = f.fact_numero + f.fact_tipo + f.fact_sucursal
JOIN Producto p ON i.item_producto = p.prod_codigo
WHERE f.fact_vendedor IN (SELECT TOP 2 empl_codigo FROM Empleado ORDER BY empl_comision DESC) AND p.prod_codigo IN (SELECT comp_producto FROM Composicion)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING COUNT(DISTINCT f.fact_numero+f.fact_tipo+f.fact_sucursal) > 5
ORDER BY 3 DESC

/*25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.*/

SELECT 
	YEAR(f.fact_fecha) año,
	p.prod_familia familia,
	(SELECT COUNT(DISTINCT prod_rubro) FROM Producto WHERE prod_familia = p.prod_familia) cant_rubros,
	(SELECT COUNT(DISTINCT comp_componente) 
		FROM Composicion 
		WHERE comp_producto IN (SELECT TOP 1 p1.prod_codigo 
									FROM Producto p1
									JOIN Item_Factura i1 ON i1.item_producto = p1.prod_codigo
									JOIN Factura f1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
									WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND p1.prod_familia = p.prod_familia
									GROUP BY p1.prod_codigo
									ORDER BY SUM(i1.item_cantidad)
									)
	) cant_componentes_producto_mas_vendido,
	COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) cant_facturas,
	(SELECT TOP 1 f1.fact_cliente 
		FROM Factura f1
		JOIN Item_Factura i1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal
		JOIN Producto p1 ON i1.item_producto = p1.prod_codigo
		WHERE p1.prod_familia = p.prod_familia AND YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY f1.fact_cliente
		ORDER BY SUM(i1.item_cantidad) DESC),
	(SUM(i.item_cantidad * i.item_precio) * 100 / (SELECT 
													SUM(fact_total) 
													FROM Factura 
													WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha))
	) porcentaje
FROM Factura f
JOIN Item_Factura i ON i.item_numero + i.item_tipo + i.item_sucursal = f.fact_numero + f.fact_tipo + f.fact_sucursal
JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE p.prod_familia = (SELECT TOP 1 p1.prod_familia 
						FROM Producto p1
						JOIN Item_Factura i1 ON i1.item_producto = p1.prod_codigo
						JOIN Factura f1 ON i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal 
						WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
						GROUP BY p1.prod_familia
						ORDER BY COUNT(*) DESC)
GROUP BY YEAR(f.fact_fecha), p.prod_familia

/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
 Empleado
 Depósitos que tiene a cargo
 Monto total facturado en el año corriente
 Codigo de Cliente al que mas le vendió
 Producto más vendido
 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT 
	RTRIM(e.empl_nombre) + ' ' + RTRIM(e.empl_apellido) Empleado,
	(SELECT COUNT(DISTINCT depo_codigo) FROM DEPOSITO WHERE depo_encargado = e.empl_codigo), 
	SUM(f.fact_total) total_facturado,
	(SELECT TOP 1 f1.fact_cliente 
	FROM Factura f1 
	WHERE f1.fact_vendedor = e.empl_codigo AND YEAR(f1.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
	GROUP BY f1.fact_cliente
	ORDER BY COUNT(*) DESC
) mejor_cliente,
	(SELECT TOP 1 i1.item_producto
	FROM Item_Factura i1 
	JOIN Factura f1 ON i1.item_tipo + i1.item_numero + i1.item_sucursal = f1.fact_tipo + f1.fact_numero + f1.fact_sucursal
	WHERE f1.fact_vendedor = e.empl_codigo AND YEAR(f1.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
	GROUP BY i1.item_producto
	ORDER BY SUM(i1.item_cantidad) DESC
) producto_mas_vendido,
 SUM(f.fact_total) * 100 / (SELECT SUM(f1.fact_total) FROM Factura f1 WHERE YEAR(f1.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)) 
FROM Empleado e
JOIN Factura f ON f.fact_vendedor = e.empl_codigo
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura) 
GROUP BY e.empl_nombre, e.empl_apellido, e.empl_codigo
ORDER BY 3 DESC

/*27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
 Año
 Codigo de envase
 Detalle del envase
 Cantidad de productos que tienen ese envase
 Cantidad de productos facturados de ese envase
 Producto mas vendido de ese envase
 Monto total de venta de ese envase en ese año
 Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor*/


SELECT YEAR(f.fact_fecha), e.enva_codigo, e.enva_detalle, COUNT(DISTINCT p.prod_codigo) cant_productos, SUM(i.item_cantidad) productos_facturados,
(SELECT TOP 1 prod_codigo 
	FROM Producto 
	JOIN Item_Factura ON item_producto = prod_codigo
	JOIN Factura ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal 
	WHERE prod_envase = e.enva_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
	GROUP BY prod_codigo
	ORDER BY SUM(item_cantidad) DESC
	) producto_mas_vendido,
SUM(i.item_cantidad * i.item_precio) monto_total,
SUM(i.item_cantidad * i.item_precio) * 100 / (SELECT SUM(fact_total) FROM Factura WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)) porcentaje
FROM Envases e
JOIN Producto p ON p.prod_envase = e.enva_codigo
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
GROUP BY YEAR(f.fact_fecha), e.enva_codigo, e.enva_detalle
ORDER BY 1, 7 DESC


SELECT COUNT(DISTINCT prod_codigo) 
FROM Producto 
JOIN ITEM_FACTURA ON item_producto = prod_codigo 
JOIN FACTURA ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal 
WHERE prod_envase = 1 AND YEAR(fact_fecha) = 2010



/*28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT 
	YEAR(f.fact_fecha) año, 
	e.empl_codigo, 
	RTRIM(e.empl_nombre) + ' ' + RTRIM(e.empl_apellido) detalle_vendedor, 
	COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) cant_facturas,
	COUNT(DISTINCT f.fact_cliente) cant_clientes,
	(SELECT COUNT(*) 
		FROM Item_Factura 
		JOIN Factura ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal 
		JOIN Composicion ON item_producto = comp_producto
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = e.empl_codigo
		) cant_prods_composicion,
	(SELECT COUNT(*) 
		FROM Item_Factura 
		JOIN Factura ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal 
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = e.empl_codigo AND item_producto NOT IN (SELECT comp_producto FROM Composicion)
		) cant_prods_sin_composicion,
	SUM(i.item_cantidad * i.item_precio) monto_total
FROM Factura f
JOIN Item_Factura i ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
JOIN Empleado e ON f.fact_vendedor = e.empl_codigo
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, e.empl_nombre, e.empl_apellido 
ORDER BY 1, COUNT(DISTINCT i.item_producto) DESC


/*29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:
a. Código de producto
b. Descripción del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) unidades_vendidas, COUNT(DISTINCT f.fact_tipo + f.fact_numero + f.fact_sucursal) cant_facturas, SUM(i.item_cantidad * i.item_precio) monto_recaudado
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
WHERE YEAR(f.fact_fecha) = 2011 AND p.prod_familia IN ( SELECT fami_id FROM Familia JOIN Producto ON prod_familia = fami_id GROUP BY fami_id HAVING COUNT(*) > 20)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY 3 DESC

/*30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
 Nombre del Jefe
 Cantidad de empleados a cargo
 Monto total vendido de los empleados a cargo
 Cantidad de facturas realizadas por los empleados a cargo
 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/

SELECT j.empl_nombre jefe, COUNT(DISTINCT e.empl_codigo) cant_subordinados, ISNULL(SUM(f.fact_total),0) total_recaudado, COUNT(f.fact_vendedor) cant_facturas,
ISNULL((SELECT TOP 1 empl_nombre 
	FROM Empleado 
	JOIN Factura ON empl_codigo = fact_vendedor
	WHERE empl_jefe = j.empl_codigo
	GROUP BY empl_nombre
	ORDER BY SUM(fact_total) DESC), 'NO TIENE') mejor_vendedor
FROM Empleado e  
LEFT JOIN Empleado j ON e.empl_jefe = j.empl_codigo 
LEFT JOIN Factura f ON f.fact_vendedor = e.empl_codigo
WHERE YEAR(f.fact_fecha) = 2012 OR f.fact_fecha IS NULL
GROUP BY j.empl_nombre, j.empl_codigo
ORDER BY 3 DESC

/*31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(f.fact_fecha) año, e.empl_codigo, RTRIM(e.empl_nombre) + ' ' + RTRIM(e.empl_apellido), COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) cant_facturas, COUNT(DISTINCT f.fact_cliente) cant_clientes, 
(SELECT COUNT(DISTINCT item_producto)
	FROM Item_Factura
	JOIN Factura ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal AND YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = e.empl_codigo
	JOIN Composicion ON item_producto = comp_producto
	) cant_prods_comp,
(SELECT COUNT(DISTINCT item_producto)
	FROM Item_Factura
	JOIN Factura ON fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal  AND YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = e.empl_codigo
	WHERE item_producto NOT IN (SELECT comp_producto FROM Composicion) 	
) cant_prods_sin_comp,
SUM(i.item_precio * i.item_cantidad) monto_total
FROM Factura f
JOIN Item_Factura i ON f.fact_numero + f.fact_tipo + f.fact_sucursal = i.item_numero + i.item_tipo + i.item_sucursal 
JOIN Empleado e ON e.empl_codigo = f.fact_vendedor
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, e.empl_nombre, e.empl_apellido
ORDER BY 1, COUNT(DISTINCT i.item_producto) DESC

/*32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:
 Código de familia
 Detalle de familia
 Código de familia
 Detalle de familia
 Cantidad de facturas
 Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces.*/

SELECT f1.fami_id, f1.fami_detalle, f2.fami_id, f2.fami_detalle, COUNT(f.fact_tipo + f.fact_numero + f.fact_sucursal), SUM(i1.item_precio * i1.item_cantidad)+ SUM(i2.item_precio * i2.item_cantidad)
FROM Factura f
JOIN Item_Factura i1 ON i1.item_tipo + i1.item_numero + i1.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
JOIN Item_Factura i2 ON i2.item_tipo + i2.item_numero + i2.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
JOIN Producto p1 ON p1.prod_codigo = i1.item_producto
JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
JOIN Familia f1 ON f1.fami_id = p1.prod_familia
JOIN Familia f2 ON f2.fami_id = p2.prod_familia
WHERE f1.fami_id > f2.fami_id
GROUP BY f1.fami_id, f1.fami_detalle, f2.fami_id, f2.fami_detalle
HAVING COUNT(DISTINCT f.fact_numero + f.fact_sucursal + f.fact_tipo) > 10
ORDER BY 6 


/*33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:
a. Código de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012.*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) unidades_vendidas, COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) cant_facturas, AVG(i.item_precio * i.item_cantidad) precio_promedio, SUM(i.item_precio * i.item_cantidad)
FROM Producto p
JOIN Composicion c ON c.comp_componente = p.prod_codigo
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_tipo + i.item_numero + i.item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal
WHERE YEAR(f.fact_fecha) = 2012 AND c.comp_producto IN (SELECT TOP 1 item_producto 
														FROM Item_Factura 
														JOIN Factura ON item_tipo + item_numero + item_sucursal = fact_tipo + fact_numero + fact_sucursal
														JOIN Composicion ON item_producto = comp_componente
														WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)
														GROUP BY item_producto
														ORDER BY SUM(item_cantidad) DESC
														)
GROUP BY p.prod_codigo, p.prod_detalle

