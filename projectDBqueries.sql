-- Project DB Reporting Queries
-- File: projectDBqueries.sql
-- Contains 10 reporting queries addressing the 10 business goals and sample expected outputs.

-- BUSINESS GOAL 1: Top 3 brands with highest profit margins (>= 20%)
-- Query 1) Brand profitability: brands with profit margin > 20%
-- Expected output columns: brand, total_revenue, total_cost, total_profit, profit_margin
WITH orig AS (
  SELECT p.brand,
         SUM(bd.quantity * p.price) AS total_revenue,
         SUM(bd.quantity * NVL(s.avg_cost,0)) AS total_cost,
         SUM(bd.quantity * p.price) - SUM(bd.quantity * NVL(s.avg_cost,0)) AS total_profit,
         (SUM(bd.quantity * p.price) - SUM(bd.quantity * NVL(s.avg_cost,0))) / NULLIF(SUM(bd.quantity * p.price),0) AS profit_margin
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_PRODUCT p     ON bd.product_id = p.product_id
  LEFT JOIN (
      SELECT product_id, AVG(unit_cost) AS avg_cost
      FROM Fall25_S003_T8_SUPPLIES_DETAILS
      GROUP BY product_id
  ) s ON p.product_id = s.product_id
  GROUP BY p.brand
  HAVING (SUM(bd.quantity * p.price) - SUM(bd.quantity * NVL(s.avg_cost,0))) / NULLIF(SUM(bd.quantity * p.price),0) > 0.20
)
SELECT * FROM orig
UNION ALL
SELECT 'No data' AS brand, 0 AS total_revenue, 0 AS total_cost, 0 AS total_profit, 0 AS profit_margin
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM orig)
ORDER BY profit_margin DESC;

-- Sample expected output (illustrative):
-- brand | total_revenue | total_cost | total_profit | profit_margin
-- Ray-Ban | 1050.00 | 450.00 | 600.00 | 0.5714
-- Oakley  | 1450.00 | 1050.00 | 400.00 | 0.2759
-- Maui Jim| 329.00  | 150.00  | 179.00 | 0.5438


-- BUSINESS GOAL 2: Top 3 eyewear models (glasses, sunglasses, contact lenses) purchased by customers in 30-40 age group
-- Query 2) Top 3 eyewear models purchased by customers aged 30-40
-- Expected output: model, total_purchased
WITH orig AS (
  SELECT p.model,
         SUM(bd.quantity) AS total_purchased
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_PRODUCT p ON bd.product_id = p.product_id
  JOIN Fall25_S003_T8_CUSTOMER c ON bd.cust_person_id = c.cust_person_id
  JOIN Fall25_S003_T8_PERSON per ON c.cust_person_id = per.person_id
  WHERE FLOOR(MONTHS_BETWEEN(SYSDATE, per.dob) / 12) BETWEEN 30 AND 40
  GROUP BY p.model
  ORDER BY total_purchased DESC
  FETCH FIRST 3 ROWS ONLY
)
SELECT * FROM orig
UNION ALL
SELECT 'No data' AS model, 0 AS total_purchased FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig);

-- Sample expected output (illustrative):
-- model | total_purchased
-- Radar EV | 18
-- Clubmaster | 15
-- Aviator Large | 12


-- BUSINESS GOAL 3: Top 3 staff members who achieved the most sales in quantity and value for each quarter
-- Query 3) Top 3 staff per quarter by quantity and value (uses OVER)
-- Expected output: quarter_label, emp_person_id, emp_id, total_qty, total_value, top_qty_flag, top_value_flag
WITH emp_quarter AS (
  SELECT sd.emp_person_id,
         TRUNC(sd.date_sold, 'Q') AS quarter_start,
         SUM(sd.quantity)          AS total_qty,
         SUM(sd.quantity * p.price) AS total_value
  FROM Fall25_S003_T8_SELLS_DETAILS sd
  JOIN Fall25_S003_T8_PRODUCT p ON sd.product_id = p.product_id
  GROUP BY sd.emp_person_id, TRUNC(sd.date_sold, 'Q')
)
, ranked AS (
  SELECT eq.*,
         ROW_NUMBER() OVER (PARTITION BY eq.quarter_start ORDER BY eq.total_qty DESC, eq.total_value DESC)   AS rn_by_qty,
         ROW_NUMBER() OVER (PARTITION BY eq.quarter_start ORDER BY eq.total_value DESC, eq.total_qty DESC) AS rn_by_value
  FROM emp_quarter eq
)
WITH ranked_results AS (
  SELECT TO_CHAR(r.quarter_start,'YYYY-"Q"Q') AS quarter_label,
         e.emp_person_id,
         e.emp_id,
         r.total_qty,
         r.total_value,
         CASE WHEN r.rn_by_qty <= 3 THEN 'Top-3-by-qty' ELSE NULL END AS top_qty_flag,
         CASE WHEN r.rn_by_value <= 3 THEN 'Top-3-by-value' ELSE NULL END AS top_value_flag
  FROM ranked r
  JOIN Fall25_S003_T8_EMPLOYEE e ON e.emp_person_id = r.emp_person_id
  WHERE r.rn_by_qty <= 3 OR r.rn_by_value <= 3
)
SELECT * FROM ranked_results
UNION ALL
SELECT 'No data' AS quarter_label, NULL AS emp_person_id, 'No data' AS emp_id, 0 AS total_qty, 0 AS total_value, NULL AS top_qty_flag, NULL AS top_value_flag
FROM dual
WHERE NOT EXISTS (SELECT 1 FROM ranked_results)
ORDER BY quarter_label, total_qty DESC, total_value DESC;

-- Sample expected output (illustrative):
-- quarter_label | emp_person_id | emp_id | total_qty | total_value | top_qty_flag | top_value_flag
-- 2024 Q1 | 52 | EMP002 | 24 | 3720.00 | Top-3-by-qty | Top-3-by-value
-- 2024 Q1 | 53 | EMP003 | 18 | 2700.00 | Top-3-by-qty |
-- 2024 Q1 | 54 | EMP004 | 12 | 1950.00 | Top-3-by-qty |


-- BUSINESS GOAL 4: Top 5 underperforming products in the last quarter of the year
-- Query 4) Top 5 underperforming products in the last quarter (qty < average that quarter)
-- Expected output: product_id, model, total_qty
WITH orig AS (
  SELECT p.product_id, p.model, SUM(bd.quantity) AS total_qty
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_PRODUCT p ON bd.product_id = p.product_id
  WHERE TO_CHAR(bd.buy_date,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -3),'YYYY')
    AND TO_CHAR(bd.buy_date,'Q') = TO_CHAR(ADD_MONTHS(SYSDATE, -3),'Q')
  GROUP BY p.product_id, p.model
  HAVING SUM(bd.quantity) < (
      SELECT AVG(prod_qty) FROM (
        SELECT SUM(bd2.quantity) AS prod_qty
        FROM Fall25_S003_T8_BUYS_DETAILS bd2
        WHERE TO_CHAR(bd2.buy_date,'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE,-3),'YYYY')
          AND TO_CHAR(bd2.buy_date,'Q') = TO_CHAR(ADD_MONTHS(SYSDATE,-3),'Q')
        GROUP BY bd2.product_id
      )
  )
  ORDER BY total_qty ASC
  FETCH FIRST 5 ROWS ONLY
)
SELECT * FROM orig
UNION ALL
SELECT 0 AS product_id, 'No data' AS model, 0 AS total_qty FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig)
ORDER BY total_qty ASC;

-- Sample expected output (illustrative):
-- product_id | model | total_qty
-- 27 | Model-X | 2
-- 35 | Model-Y | 1
-- 41 | Model-Z | 0


-- BUSINESS GOAL 5: Months with maximum sunglasses sales to identify peak demand periods
-- Query 5) Months with maximum sunglasses sales (LIKE + CUBE, ORDER BY + FETCH)
-- Expected output: year_month, brand, total_sold
WITH orig AS (
  SELECT TO_CHAR(bd.buy_date,'YYYY-MM') AS year_month,
         p.brand,
         SUM(bd.quantity) AS total_sold
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_PRODUCT p ON bd.product_id = p.product_id
  WHERE LOWER(p.category) LIKE '%sunglasses%'
  GROUP BY CUBE(TO_CHAR(bd.buy_date,'YYYY-MM'), p.brand)
  ORDER BY year_month NULLS LAST, total_sold DESC
  FETCH FIRST 5 ROWS ONLY
)
SELECT * FROM orig
UNION ALL
SELECT 'No data' AS year_month, 'No data' AS brand, 0 AS total_sold FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig);

-- Sample expected output (illustrative):
-- year_month | brand | total_sold
-- 2024-08 | Oakley | 120
-- 2024-07 | Ray-Ban | 95
-- 2024-09 | Maui Jim | 78


-- BUSINESS GOAL 6: Products completely sold out during a season (high-demand items to prioritize for restocking)
-- Query 6) Products completely sold out during a season (sold >= supplied for that season)
-- Expected output: product_id, model, season, total_sold, total_supplied
WITH supplies_season AS (
  SELECT sd.product_id,
         CASE
           WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (6,7,8) THEN 'Summer'
           WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (12,1,2) THEN 'Winter'
           WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (3,4,5) THEN 'Spring'
           ELSE 'Fall'
         END AS season,
         SUM(sd.quantity) AS total_supplied
  FROM Fall25_S003_T8_SUPPLIES_DETAILS sd
  GROUP BY sd.product_id,
           CASE
             WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (6,7,8) THEN 'Summer'
             WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (12,1,2) THEN 'Winter'
             WHEN TO_NUMBER(TO_CHAR(sd.supply_date,'MM')) IN (3,4,5) THEN 'Spring'
             ELSE 'Fall'
           END
),
sales_season AS (
  SELECT bd.product_id,
         CASE
           WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (6,7,8) THEN 'Summer'
           WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (12,1,2) THEN 'Winter'
           WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (3,4,5) THEN 'Spring'
           ELSE 'Fall'
         END AS season,
         SUM(bd.quantity) AS total_sold
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  GROUP BY bd.product_id,
           CASE
             WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (6,7,8) THEN 'Summer'
             WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (12,1,2) THEN 'Winter'
             WHEN TO_NUMBER(TO_CHAR(bd.buy_date,'MM')) IN (3,4,5) THEN 'Spring'
             ELSE 'Fall'
           END
)
WITH orig AS (
  SELECT p.product_id, p.model, s_season.season, s_season.total_sold, sup_season.total_supplied
  FROM sales_season s_season
  JOIN supplies_season sup_season
    ON s_season.product_id = sup_season.product_id
   AND s_season.season = sup_season.season
  JOIN Fall25_S003_T8_PRODUCT p ON p.product_id = s_season.product_id
  WHERE s_season.total_sold >= sup_season.total_supplied
)
SELECT * FROM orig
UNION ALL
SELECT 0 AS product_id, 'No data' AS model, 'No data' AS season, 0 AS total_sold, 0 AS total_supplied FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig)
ORDER BY season, product_id;

-- Sample expected output (illustrative):
-- product_id | model | season | total_sold | total_supplied
-- 15 | Radar EV | Summer | 200 | 180
-- 23 | Sunset Shades | Winter | 45 | 40


-- BUSINESS GOAL 7: Most used payment method to explore future partnerships with payment providers
-- Query 7) Most used payment method (by number of transactions)
-- Expected output: payment_method, usage_count, distinct_customers
WITH orig AS (
  SELECT bd.payment_method,
         COUNT(*) AS usage_count,
         COUNT(DISTINCT bd.cust_person_id) AS distinct_customers
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_CUSTOMER c ON bd.cust_person_id = c.cust_person_id
  GROUP BY bd.payment_method
  ORDER BY usage_count DESC
  FETCH FIRST 1 ROW ONLY
)
SELECT * FROM orig
UNION ALL
SELECT 'No data' AS payment_method, 0 AS usage_count, 0 AS distinct_customers FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig);

-- Sample expected output (illustrative):
-- payment_method | usage_count | distinct_customers
-- Debit Card | 120 | 98


-- BUSINESS GOAL 8: Number of prescriptions issued by each optometrist and average per optometrist
-- Query 8) Prescriptions per optometrist and average per optometrist (uses OVER)
-- Expected output: opti_emp_person_id, opt_emp_id, num_prescriptions, avg_prescriptions_per_optometrist
WITH orig AS (
  SELECT opti_emp_person_id,
         opt_emp_id,
         num_prescriptions,
         ROUND(AVG(num_prescriptions) OVER (),2) AS avg_prescriptions_per_optometrist
  FROM (
    SELECT o.opti_emp_person_id,
           o.opt_emp_id,
           COUNT(pr.prescription_id) AS num_prescriptions
    FROM Fall25_S003_T8_OPTOMETRIST o
    LEFT JOIN Fall25_S003_T8_PRESCRIPTION pr ON pr.opti_emp_person_id = o.opti_emp_person_id
    GROUP BY o.opti_emp_person_id, o.opt_emp_id
  ) t
)
SELECT * FROM orig
UNION ALL
SELECT 0 AS opti_emp_person_id, 'No data' AS opt_emp_id, 0 AS num_prescriptions, 0 AS avg_prescriptions_per_optometrist FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig)
ORDER BY num_prescriptions DESC;

-- Sample expected output (illustrative):
-- opti_emp_person_id | opt_emp_id | num_prescriptions | avg_prescriptions_per_optometrist
-- 91 | OPT001 | 12 | 5.40
-- 92 | OPT002 | 10 | 5.40
-- 93 | OPT003 | 8  | 5.40


-- BUSINESS GOAL 9: Top 3 suppliers contributing the highest revenue share
-- Query 9) Suppliers contributing highest revenue share (top 5)
-- Expected output: supplier_id, name, supplier_revenue, pct_of_total
WITH supplier_revenue AS (
  SELECT sup.supplier_id,
         sup.name,
         SUM(bd.quantity * p.price) AS supplier_revenue
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_PRODUCT p ON bd.product_id = p.product_id
  JOIN Fall25_S003_T8_SUPPLIES s ON s.product_id = p.product_id
  JOIN Fall25_S003_T8_SUPPLIER sup ON sup.supplier_id = s.supplier_id
  GROUP BY sup.supplier_id, sup.name
),
total_rev AS (
  SELECT SUM(supplier_revenue) AS total_revenue FROM supplier_revenue
)
SELECT * FROM (
  SELECT sr.supplier_id, sr.name, sr.supplier_revenue,
         ROUND((sr.supplier_revenue / tr.total_revenue) * 100, 2) AS pct_of_total
  FROM supplier_revenue sr CROSS JOIN total_rev tr
  ORDER BY sr.supplier_revenue DESC
  FETCH FIRST 5 ROWS ONLY
)
UNION ALL
SELECT 0 AS supplier_id, 'No data' AS name, 0 AS supplier_revenue, 0 AS pct_of_total FROM dual
WHERE NOT EXISTS (SELECT 1 FROM supplier_revenue);

-- Sample expected output (illustrative):
-- supplier_id | name | supplier_revenue | pct_of_total
-- 3 | VisionSupply Inc. | 12,500.00 | 22.45
-- 1 | LensMakers Ltd.   | 9,800.00  | 17.59
-- 5 | SunOptic Co.      | 7,300.00  | 13.10


-- BUSINESS GOAL 10: Warranty counts (active, expired, claimed) and average warranty period per quarter
-- Query 10) Warranty counts and average warranty period per quarter (ROLLUP)
-- Expected output: year_quarter, status, warranty_count, avg_warranty_months
WITH orig AS (
  SELECT TO_CHAR(TRUNC(bd.buy_date,'Q'),'YYYY "Q"Q') AS year_quarter,
         w.status,
         COUNT(*) AS warranty_count,
         ROUND(AVG(TO_NUMBER(REGEXP_SUBSTR(w.period,'[0-9]+'))),2) AS avg_warranty_months
  FROM Fall25_S003_T8_BUYS_DETAILS bd
  JOIN Fall25_S003_T8_WARRANTY w ON bd.warr_no = w.warr_no
  GROUP BY ROLLUP(TO_CHAR(TRUNC(bd.buy_date,'Q'),'YYYY "Q"Q'), w.status)
)
SELECT * FROM orig
UNION ALL
SELECT 'No data' AS year_quarter, 'No data' AS status, 0 AS warranty_count, 0 AS avg_warranty_months FROM dual WHERE NOT EXISTS (SELECT 1 FROM orig)
ORDER BY year_quarter NULLS FIRST, status;

-- Sample expected output (illustrative):
-- year_quarter | status | warranty_count | avg_warranty_months
-- 2024 Q1 | Active | 45 | 18.00
-- 2024 Q1 | Expired | 8 | 12.00
-- 2024 Q1 | (NULL)  | 53 | 16.50

-- Sample expected output (illustrative):
-- supplier_id | name
-- 2 | GlobalOptics Ltd.
