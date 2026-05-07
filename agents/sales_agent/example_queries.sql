-- ============================================================
-- Sales Agent — Example Queries
-- Paste these as example Q&A pairs when configuring the
-- Fabric Data Agent to improve SQL generation accuracy.
-- ============================================================

-- Q: "How did the Northeast region perform last week?"
SELECT
    reg_name,
    COUNT(DISTINCT ord_id)          AS total_orders,
    SUM(qty)                        AS total_units,
    SUM(line_total)                 AS total_revenue,
    SUM(line_margin_amt)            AS total_margin,
    SUM(line_total) / NULLIF(COUNT(DISTINCT ord_id), 0)
                                    AS avg_basket_size
FROM retail.vw_sales_summary
WHERE reg_name = 'Northeast'
  AND order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY reg_name;


-- Q: "What are the top 10 selling products this month?"
SELECT TOP 10
    prod_name,
    brand_name,
    cat_name,
    SUM(qty)            AS total_units,
    SUM(line_total)     AS total_revenue
FROM retail.vw_sales_summary
WHERE order_date >= DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))
GROUP BY prod_name, brand_name, cat_name
ORDER BY total_revenue DESC;


-- Q: "Show me daily revenue trend for the Southeast region"
SELECT
    order_date,
    COUNT(DISTINCT ord_id)  AS orders,
    SUM(line_total)         AS revenue
FROM retail.vw_sales_summary
WHERE reg_name = 'Southeast'
  AND order_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
GROUP BY order_date
ORDER BY order_date;


-- Q: "Which departments have the highest margin?"
SELECT
    depa_name,
    SUM(line_total)         AS revenue,
    SUM(line_margin_amt)    AS margin,
    SUM(line_margin_amt) / NULLIF(SUM(line_total), 0) * 100
                            AS margin_pct
FROM retail.vw_sales_summary
WHERE order_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
GROUP BY depa_name
ORDER BY margin DESC;


-- Q: "How many expedited orders did we have this week?"
SELECT
    reg_name,
    COUNT(DISTINCT ord_id)  AS expedited_orders,
    SUM(line_total)         AS expedited_revenue
FROM retail.vw_sales_summary
WHERE is_expedited = 1
  AND order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY reg_name
ORDER BY expedited_orders DESC;


-- Q: "Compare this week vs last week revenue by region"
SELECT
    reg_name,
    SUM(CASE WHEN order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
             THEN line_total ELSE 0 END)    AS this_week_revenue,
    SUM(CASE WHEN order_date >= DATEADD(DAY, -14, CAST(GETDATE() AS DATE))
              AND order_date <  DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
             THEN line_total ELSE 0 END)    AS last_week_revenue
FROM retail.vw_sales_summary
WHERE order_date >= DATEADD(DAY, -14, CAST(GETDATE() AS DATE))
GROUP BY reg_name
ORDER BY reg_name;


-- Q: "Payment method breakdown"
SELECT
    paym_method_type,
    COUNT(DISTINCT ord_id)  AS order_count,
    SUM(line_total)         AS revenue
FROM retail.vw_sales_summary
WHERE order_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
GROUP BY paym_method_type
ORDER BY revenue DESC;
