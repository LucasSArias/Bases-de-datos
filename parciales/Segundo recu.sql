/*Armar una consulta que muestre para todos los productos y todos los depósitos
su stock, si no tuviera stock indicará 0. Por ejemplo si hay 2 productos y dos
depósitos deberá devolver 4 filas con el stock de cada producto en cada deposito
o 0 si no tuviera stock:
Mostrar:
Producto, Detalle del producto, deposito, stock del depósito o 0 si no tiene.*/

SELECT prod_codigo, prod_detalle, depo_codigo, ISNULL( (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = prod_codigo AND stoc_deposito = depo_codigo ) , 0) cantidad
FROM Producto, DEPOSITO
GROUP BY prod_codigo, prod_detalle, depo_codigo


/*Cree el/los objetos de bases de datos necesarios para que, ante el intento de
eliminar una o mas facturas, en su lugar se genere una nota de crédito por cada
una y se reponga el stock de los productos comprados en la(s) factura(s) que se
intentaron eliminar.
El criterio de reposicion de stock debe ser asignarlo a un deposito que aun no
tenga ese producto y seteando el stock maximo como un 50% mas del stock
reingresado.
La nota de crédito se debe generar como print de pantalla de la siguiente manera:
"Nota de crédito generada: NC-fact_tipo-fact_sucursal-fact_numero Importe:
fact_total"*/

-- que es esta mierda