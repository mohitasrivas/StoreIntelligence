-- ============================================================
-- Labor Agent — Example Queries
-- ============================================================

-- Q: "How many associates per store?"
SELECT
    store_name,
    store_type,
    reg_name,
    COUNT(DISTINCT associate_id)    AS headcount
FROM retail.vw_labor_coverage
GROUP BY store_name, store_type, reg_name
ORDER BY headcount ASC;


-- Q: "Which stores are understaffed compared to average?"
WITH store_hc AS (
    SELECT
        store_id,
        store_name,
        store_type,
        reg_name,
        COUNT(DISTINCT associate_id) AS headcount
    FROM retail.vw_labor_coverage
    GROUP BY store_id, store_name, store_type, reg_name
),
type_avg AS (
    SELECT
        store_type,
        AVG(CAST(headcount AS FLOAT)) AS avg_headcount
    FROM store_hc
    GROUP BY store_type
)
SELECT
    s.store_name,
    s.store_type,
    s.reg_name,
    s.headcount,
    ROUND(t.avg_headcount, 1) AS avg_for_type,
    s.headcount - ROUND(t.avg_headcount, 0) AS delta
FROM store_hc s
JOIN type_avg t ON t.store_type = s.store_type
WHERE s.headcount < t.avg_headcount
ORDER BY delta ASC;


-- Q: "Shift coverage breakdown for Store 42"
SELECT
    shift,
    COUNT(DISTINCT associate_id)    AS associates,
    SUM(orders_managed)             AS total_orders_managed,
    SUM(tasks_completed)            AS total_tasks_completed
FROM retail.vw_labor_coverage
WHERE store_name LIKE '%42%'
GROUP BY shift
ORDER BY shift;


-- Q: "Role distribution across all stores"
SELECT
    role,
    COUNT(DISTINCT associate_id)    AS total_associates,
    COUNT(DISTINCT store_id)        AS stores_with_role,
    AVG(CAST(orders_managed AS FLOAT))  AS avg_orders_per_associate,
    AVG(CAST(tasks_completed AS FLOAT)) AS avg_tasks_per_associate
FROM retail.vw_labor_coverage
GROUP BY role
ORDER BY total_associates DESC;


-- Q: "Stores with single-associate shifts (coverage risk)"
SELECT
    store_name,
    reg_name,
    shift,
    COUNT(DISTINCT associate_id) AS associates
FROM retail.vw_labor_coverage
GROUP BY store_name, reg_name, shift
HAVING COUNT(DISTINCT associate_id) = 1
ORDER BY store_name, shift;


-- Q: "Top 10 most productive associates"
SELECT TOP 10
    associate_id,
    store_name,
    role,
    shift,
    orders_managed,
    tasks_completed,
    orders_managed + tasks_completed AS total_activity
FROM retail.vw_labor_coverage
ORDER BY total_activity DESC;


-- Q: "Average productivity by region"
SELECT
    reg_name,
    COUNT(DISTINCT associate_id)            AS headcount,
    AVG(CAST(orders_managed AS FLOAT))      AS avg_orders_managed,
    AVG(CAST(tasks_completed AS FLOAT))     AS avg_tasks_completed
FROM retail.vw_labor_coverage
GROUP BY reg_name
ORDER BY avg_orders_managed DESC;
