-- Configuramos el uso de Database y Schema

USE DATABASE MASTER;
USE SCHEMA SMART_DESK;

-- Query 1



SELECT category AS "Categoría",
       ROUND(SUM(maintenance),2) AS "Mantenimiento",
       ROUND(SUM(product),2) AS "Producto",
       ROUND(SUM(parts),2) AS "Partes",
       ROUND(SUM(support),2) AS "Soporte",
       ROUND(SUM(total),2) AS "Total Ventas",                   -- También puedes escribirse como Mantenimiento + Producto + Partes + Soporte AS "Total Ventas"
       -- Mantenimiento + Producto + Partes + Soporte AS "Total Ventas",
       ROUND(SUM(units_sold),2) AS "Unidades Vendidas",
       ROUND(SUM(profit),2) AS "Beneficio Total"
FROM sales
WHERE year = 2020 AND account = 'Adabs Entertainment'
GROUP BY category, year;

SELECT category AS "Categoría",
       year AS "Año",
       ROUND(SUM(maintenance),2) AS "Mantenimiento",
       ROUND(SUM(product),2) AS "Producto",
       ROUND(SUM(parts),2) AS "Partes",
       ROUND(SUM(support),2) AS "Soporte",
       ROUND(SUM(total),2) AS "Total Ventas",                   -- También puedes escribirse como Mantenimiento + Producto + Partes + Soporte AS "Total Ventas"
       -- Mantenimiento + Producto + Partes + Soporte AS "Total Ventas",
       ROUND(SUM(units_sold),2) AS "Unidades Vendidas",
       ROUND(SUM(profit),2) AS "Beneficio Total"
FROM sales
WHERE  account = 'Adabs Entertainment'
GROUP BY category, year;


-- Query 2

SELECT "Región",
       "País",
       ROUND(AVG("Ingreso Diario"),2) AS "Ingreso Diario Promedio",
       ROUND(AVG("Unidades Vendidas Diario"),2) AS "Unidades Vendidas Diario Promedio",
       ROUND(AVG("Beneficio Diario"),2)AS "Beneficio Diario Promerdio"
FROM (SELECT acc.region as "Región",
             acc.country as "País",
             ROUND(SUM(s.total),2) AS "Ingreso Diario",
             ROUND(SUM(s.units_sold),2) AS "Unidades Vendidas Diario",
             ROUND(SUM(s.profit),2) AS "Beneficio Diario"
      FROM  sales s 
      JOIN accounts acc ON (s.account = acc.account)
      WHERE acc.region IN ('APAC', 'EMEA')
      GROUP BY acc.region, acc.country, s.date)
GROUP BY "Región", "País"
ORDER BY "Región", "Ingreso Diario Promedio"
;


-- Alternativa con CTE

WITH ingreso_por_fecha_pais AS (
     SELECT acc.region AS "Región",
            acc.country AS "País",
            s.date AS "Fecha",
            ROUND(SUM(s.total),2) AS "Ingreso Diario",
            ROUND(SUM(s.units_sold),2) AS "Unidades Vendidas Diario",
            ROUND(SUM(s.profit),2) AS "Beneficio Diario"
     FROM  sales s 
     JOIN accounts acc ON (s.account = acc.account)
     WHERE acc.region IN ('APAC', 'EMEA')
     GROUP BY acc.region, acc.country, s.date
     ORDER BY "Región", "País", s.date
     )
SELECT "Región",
       "País",
       ROUND(AVG("Ingreso Diario"),2) AS "Ingreso Diario Promedio",
       ROUND(AVG("Unidades Vendidas Diario"),2) AS "Unidades Vendidas Diario Promedio",
       ROUND(AVG("Beneficio Diario"),2)AS "Beneficio Diario Promerdio"
FROM ingreso_por_fecha_pais
GROUP BY "Región", "País"
ORDER BY "Región", "Ingreso Diario Promedio"
;

-- Un paso extra para ver el promedio del promedio de los ingresos diarios por regiones. Hay varias alternativas, pero aquí se usa la expresión de CREATE

WITH ingreso_por_fecha_pais AS (
     SELECT acc.region AS "Región",
            acc.country AS "País",
            s.date AS "Fecha",
            ROUND(SUM(s.total),2) AS "Ingreso Diario",
            ROUND(SUM(s.units_sold),2) AS "Unidades Vendidas Diario",
            ROUND(SUM(s.profit),2) AS "Beneficio Diario"
     FROM  sales s 
     JOIN accounts acc ON (s.account = acc.account)
     WHERE acc.region IN ('APAC', 'EMEA')
     GROUP BY acc.region,  acc.country, s.date
     ORDER BY "Región", "País", s.date
     ),
ingreso_promedio_diario_pais AS (
     SELECT "Región",
            "País",
            ROUND(AVG("Ingreso Diario"),2) AS "Ingreso Diario Promedio",
            ROUND(AVG("Unidades Vendidas Diario"),2) AS "Unidades Vendidas Diario Promedio",
            ROUND(AVG("Beneficio Diario"),2)AS "Beneficio Diario Promerdio"
     FROM ingreso_por_fecha_pais
     GROUP BY "Región", "País"
     ORDER BY "Región", "País"
)
SELECT "Región",
        ROUND(AVG("Ingreso Diario Promedio"), 2) AS "Ingreso promedio diario por región"
FROM ingreso_promedio_diario_pais,
GROUP BY "Región"
;


-- Query 3
SELECT * FROM sales
WHERE account = 'FanTickets';

SELECT acc.industry AS "Industria",
       IFNULL(ROUND(SUM(s.profit), 2),0) AS "Beneficio Total",
       CASE 
            WHEN "Beneficio Total" > 1000000 THEN 'Alto' 
            ELSE 'Normal' END AS "Categoría Beneficio"
       FROM sales s 
       RIGHT JOIN accounts acc ON (s.account = acc.account AND   
                                   acc.account IN (SELECT fr.account
                                                   FROM accounts acc JOIN forecasts fr ON (acc.account = fr.account)
                                                   WHERE fr.prediction_category = 'Commit' AND fr.year='2022'
                                                   GROUP BY fr.account
                                                   HAVING SUM(fr.forecast) > 500000
                                                   )
                                    )
GROUP BY acc.industry
ORDER BY "Beneficio Total" DESC
;

SELECT fr.account
FROM accounts acc JOIN forecasts fr ON (acc.account = fr.account)
WHERE fr.prediction_category = 'Commit' AND fr.year='2022'
GROUP BY fr.account
HAVING SUM(fr.forecast) > 500000
ORDER BY fr.account
;
-- Query 4

SELECT s.year AS "Año",
       s.quarter AS "Cuartil",
       s."Sumatorio ventas reales",
       t.target_total AS "Target venta",
       s."Sumatorio beneficios reales",
       t.target_profit AS "Target beneficio",
       s."Sumatorio ventas reales" - "Target venta" AS "Desviación ventas",
       s."Sumatorio beneficios reales" - "Target beneficio" AS "Desviación beneficios"
FROM (SELECT year,
             quarter,
             ROUND(SUM(total), 2) AS "Sumatorio ventas reales",
             ROUND(SUM(profit), 2) AS "Sumatorio beneficios reales"
      FROM sales,
      GROUP BY year, quarter
    ) AS s
JOIN targets t ON (s.year = t.year AND s.quarter = t.quarter_of_year)
ORDER BY "Año", "Cuartil"
;

-- Caso práctico: Patrón semanal de ventas

-- Visión general

SELECT day_name AS "Día de la semana",
       COUNT(*) AS "Ventas totales por día de semana",
       ROUND(SUM(total), 2) AS "Ingreso por día de semana",
       ROUND(SUM(profit), 2) AS "Beneficio por día de semana",
       ROUND(SUM(units_sold), 2) AS "Unidades vendidas por día de semana",
       ROUND(AVG(total), 2) AS "Promedio de ingreso por día de semana",
       ROUND(AVG(profit),2) AS "Promedio de beneficio por día de semana",
       ROUND(AVG(units_sold), 2) AS "Promedio de unidades vendidas por día de semana"
FROM sales
GROUP BY day_name
ORDER BY CASE "Día de la semana" WHEN 'Monday' THEN 1
                                 WHEN 'Tuesday' THEN 2
                                 WHEN 'Wednesday' THEN 3
                                 WHEN 'Thursday' THEN 4
                                 WHEN 'Friday' THEN 5
                                 WHEN 'Saturday' THEN 6
                                 WHEN 'Sunday' THEN 7
        END
;

-- Por regiones

SELECT s.day_name AS "Día de la semana",
       acc.region AS "Región",
       COUNT(*) AS "Ventas totales por día de semana",
       ROUND(SUM(s.total), 2) AS "Ingreso por día de semana",
       ROUND(SUM(s.profit), 2) AS "Beneficio por día de semana",
       ROUND(SUM(s.units_sold), 2) AS "Unidades vendidas por día de semana",
       ROUND(AVG(s.total), 2) AS "Promedio de ingreso por día de semana",
       ROUND(AVG(s.profit),2) AS "Promedio de beneficio por día de semana",
       ROUND(AVG(s.units_sold), 2) AS "Promedio de unidades vendidas por día de semana"
FROM sales s JOIN accounts acc ON (s.account = acc.account)
GROUP BY s.day_name, acc.region
ORDER BY acc.region, 
         CASE "Día de la semana" WHEN 'Monday' THEN 1
                                 WHEN 'Tuesday' THEN 2
                                 WHEN 'Wednesday' THEN 3
                                 WHEN 'Thursday' THEN 4
                                 WHEN 'Friday' THEN 5
                                 WHEN 'Saturday' THEN 6
                                 WHEN 'Sunday' THEN 7
         END 
;


-- Por año
SELECT day_name AS "Día de la semana",
       year AS "Año",
       COUNT(*) AS "Ventas totales por día de semana",
       ROUND(SUM(total), 2) AS "Ingreso por día de semana",
       ROUND(SUM(profit), 2) AS "Beneficio por día de semana",
       ROUND(SUM(units_sold), 2) AS "Unidades vendidas por día de semana",
       ROUND(AVG(total), 2) AS "Promedio de ingreso por día de semana",
       ROUND(AVG(profit),2) AS "Promedio de beneficio por día de semana",
       ROUND(AVG(units_sold), 2) AS "Promedio de unidades vendidas por día de semana"
FROM sales
GROUP BY day_name, "Año"
ORDER BY "Año", 
      CASE "Día de la semana" WHEN 'Monday' THEN 1
                                 WHEN 'Tuesday' THEN 2
                                 WHEN 'Wednesday' THEN 3
                                 WHEN 'Thursday' THEN 4
                                 WHEN 'Friday' THEN 5
                                 WHEN 'Saturday' THEN 6
                                 WHEN 'Sunday' THEN 7
        END
;

--Por industria

SELECT s.day_name AS "Día de la semana",
       acc.industry AS "Industria",
       COUNT(*) AS "Ventas totales por día de semana",
       ROUND(SUM(s.total), 2) AS "Ingreso por día de semana",
       ROUND(SUM(s.profit), 2) AS "Beneficio por día de semana",
       ROUND(SUM(s.units_sold), 2) AS "Unidades vendidas por día de semana",
       ROUND(AVG(s.total), 2) AS "Promedio de ingreso por día de semana",
       ROUND(AVG(s.profit),2) AS "Promedio de beneficio por día de semana",
       ROUND(AVG(s.units_sold), 2) AS "Promedio de unidades vendidas por día de semana"
FROM sales s JOIN accounts acc ON (s.account = acc.account)
GROUP BY s.day_name, acc.industry
ORDER BY acc.industry, 
         CASE "Día de la semana" WHEN 'Monday' THEN 1
                                 WHEN 'Tuesday' THEN 2
                                 WHEN 'Wednesday' THEN 3
                                 WHEN 'Thursday' THEN 4
                                 WHEN 'Friday' THEN 5
                                 WHEN 'Saturday' THEN 6
                                 WHEN 'Sunday' THEN 7
         END 
;

--Por categoría de productos

SELECT day_name AS "Día de la semana",
       category AS "Categoría",
       COUNT(*) AS "Ventas totales por día de semana",
       ROUND(SUM(total), 2) AS "Ingreso por día de semana",
       ROUND(SUM(profit), 2) AS "Beneficio por día de semana",
       ROUND(SUM(units_sold), 2) AS "Unidades vendidas por día de semana",
       ROUND(AVG(total), 2) AS "Promedio de ingreso por día de semana",
       ROUND(AVG(profit),2) AS "Promedio de beneficio por día de semana",
       ROUND(AVG(units_sold), 2) AS "Promedio de unidades vendidas por día de semana"
FROM sales
GROUP BY day_name, "Categoría"
ORDER BY "Categoría",
      CASE "Día de la semana" WHEN 'Monday' THEN 1
                                 WHEN 'Tuesday' THEN 2
                                 WHEN 'Wednesday' THEN 3
                                 WHEN 'Thursday' THEN 4
                                 WHEN 'Friday' THEN 5
                                 WHEN 'Saturday' THEN 6
                                 WHEN 'Sunday' THEN 7
        END
;




