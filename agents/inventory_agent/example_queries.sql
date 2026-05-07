-- ============================================================
-- Inventory Agent — Example Queries
-- ============================================================

-- Q: "Which products have inventory risk?"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    safety_stock_qty,
    reorder_point_qty,
    lead_time_days,
    risk_flag
FROM retail.vw_inventory_health
WHERE risk_flag <> 'OK'
ORDER BY risk_flag, prod_name;


-- Q: "Show perishable products where lead time exceeds shelf life"
SELECT
    prod_name,
    cat_name,
    wh_name,
    reg_name,
    lead_time_days,
    shelf_life_days,
    lead_time_days - shelf_life_days  AS days_over
FROM retail.vw_inventory_health
WHERE is_perishable = 1
  AND lead_time_days > shelf_life_days
ORDER BY days_over DESC;


-- Q: "On-shelf availability rate by store this week"
SELECT
    store_name,
    reg_name,
    COUNT(*)                                           AS total_scans,
    SUM(CAST(on_shelf_flag AS INT))                    AS on_shelf_count,
    SUM(CAST(on_shelf_flag AS INT)) * 100.0 / COUNT(*) AS osa_rate_pct
FROM retail.vw_osa_daily
WHERE osa_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY store_name, reg_name
ORDER BY osa_rate_pct ASC;


-- Q: "Which products are most often off-shelf?"
SELECT TOP 10
    prod_name,
    cat_name,
    COUNT(*)                                           AS total_scans,
    SUM(CASE WHEN on_shelf_flag = 0 THEN 1 ELSE 0 END) AS off_shelf_count,
    SUM(CASE WHEN on_shelf_flag = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
                                                        AS off_shelf_pct
FROM retail.vw_osa_daily
WHERE osa_date >= DATEADD(DAY, -14, CAST(GETDATE() AS DATE))
GROUP BY prod_name, cat_name
ORDER BY off_shelf_pct DESC;


-- Q: "On-shelf availability trend for dairy in Region 5"
SELECT
    osa_date,
    COUNT(*)                                           AS scans,
    SUM(CAST(on_shelf_flag AS INT)) * 100.0 / COUNT(*) AS osa_rate_pct
FROM retail.vw_osa_daily
WHERE depa_name = 'Dairy'
  AND osa_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
GROUP BY osa_date
ORDER BY osa_date;


-- Q: "Inventory overview for the Northwest warehouse"
SELECT
    prod_name,
    cat_name,
    safety_stock_qty,
    reorder_point_qty,
    lead_time_days,
    demand_channel,
    forecast_horizon_days,
    risk_flag
FROM retail.vw_inventory_health
WHERE wh_name LIKE '%Northwest%'
ORDER BY risk_flag DESC, prod_name;


-- Q: "Which stores have the lowest on-shelf availability?"
SELECT TOP 5
    store_name,
    store_type,
    reg_name,
    SUM(CAST(on_shelf_flag AS INT)) * 100.0 / COUNT(*) AS osa_rate_pct
FROM retail.vw_osa_daily
WHERE osa_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY store_name, store_type, reg_name
ORDER BY osa_rate_pct ASC;


-- ============================================================
-- OOS Classification Queries
-- ============================================================

-- Q: "Show me all out-of-stock products"
SELECT
    oos_classification,
    COUNT(*)  AS product_count
FROM retail.vw_oos_classification
WHERE oos_classification <> 'OK'
GROUP BY oos_classification
ORDER BY product_count DESC;


-- Q: "Which products are truly out of stock?"
SELECT
    store_name,
    prod_name,
    cat_name,
    brand_name,
    last_scan_date,
    units_sold_7d,
    days_off_shelf_14d,
    oos_classification
FROM retail.vw_oos_classification
WHERE oos_classification = 'TRUE_OOS'
ORDER BY store_name, prod_name;


-- Q: "Show me phantom out-of-stocks — where system says we have stock but shelf is empty"
SELECT
    store_name,
    prod_name,
    cat_name,
    brand_name,
    last_scan_date,
    units_sold_7d,
    revenue_7d,
    has_warehouse_inventory,
    safety_stock_qty,
    oos_classification
FROM retail.vw_oos_classification
WHERE oos_classification = 'PHANTOM_OOS'
ORDER BY revenue_7d DESC;


-- Q: "Which products are at risk of going out of stock?"
SELECT
    store_name,
    prod_name,
    cat_name,
    units_sold_7d,
    orders_7d,
    revenue_7d,
    safety_stock_qty,
    reorder_point_qty,
    lead_time_days,
    oos_classification
FROM retail.vw_oos_classification
WHERE oos_classification = 'AT_RISK_OOS'
ORDER BY units_sold_7d DESC;


-- Q: "Show me chronic out-of-stock problems"
SELECT
    store_name,
    prod_name,
    cat_name,
    depa_name,
    days_scanned_14d,
    days_off_shelf_14d,
    off_shelf_pct_14d,
    units_sold_7d,
    oos_classification
FROM retail.vw_oos_classification
WHERE oos_classification = 'CHRONIC_OOS'
ORDER BY off_shelf_pct_14d DESC;


-- Q: "OOS summary by store — which stores have the most issues?"
SELECT
    store_name,
    reg_name,
    COUNT(CASE WHEN oos_classification = 'TRUE_OOS'    THEN 1 END) AS true_oos,
    COUNT(CASE WHEN oos_classification = 'PHANTOM_OOS' THEN 1 END) AS phantom_oos,
    COUNT(CASE WHEN oos_classification = 'AT_RISK_OOS' THEN 1 END) AS at_risk,
    COUNT(CASE WHEN oos_classification = 'CHRONIC_OOS' THEN 1 END) AS chronic_oos,
    COUNT(CASE WHEN oos_classification <> 'OK'         THEN 1 END) AS total_issues
FROM retail.vw_oos_classification
GROUP BY store_name, reg_name
HAVING COUNT(CASE WHEN oos_classification <> 'OK' THEN 1 END) > 0
ORDER BY total_issues DESC;


-- Q: "OOS breakdown by category — which departments are worst?"
SELECT
    depa_name,
    cat_name,
    COUNT(CASE WHEN oos_classification = 'TRUE_OOS'    THEN 1 END) AS true_oos,
    COUNT(CASE WHEN oos_classification = 'PHANTOM_OOS' THEN 1 END) AS phantom_oos,
    COUNT(CASE WHEN oos_classification = 'AT_RISK_OOS' THEN 1 END) AS at_risk,
    COUNT(CASE WHEN oos_classification = 'CHRONIC_OOS' THEN 1 END) AS chronic_oos,
    COUNT(CASE WHEN oos_classification <> 'OK'         THEN 1 END) AS total_issues
FROM retail.vw_oos_classification
GROUP BY depa_name, cat_name
HAVING COUNT(CASE WHEN oos_classification <> 'OK' THEN 1 END) > 0
ORDER BY total_issues DESC;


-- Q: "Identify chronic out-of-stocks for perishable products"
SELECT
    store_name,
    prod_name,
    cat_name,
    days_off_shelf_14d,
    off_shelf_pct_14d,
    lead_time_days,
    oos_classification
FROM retail.vw_oos_classification
WHERE oos_classification = 'CHRONIC_OOS'
  AND is_perishable = 1
ORDER BY off_shelf_pct_14d DESC;
