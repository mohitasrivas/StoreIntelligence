/*  vw_oos_classification
    ──────────────────────
    Classifies each store × product into an out-of-stock category by combining:
      - Visual OSA scans   (store-level shelf presence)
      - Sales data         (store-level recent sales velocity)
      - Inventory params   (warehouse-level stock parameters)

    OOS Categories:
      TRUE_OOS      → off-shelf AND zero sales in last 7 days (genuinely out)
      PHANTOM_OOS   → off-shelf BUT warehouse inventory exists (system says in-stock,
                      shelf is empty — likely a shelving / location issue)
      AT_RISK_OOS   → currently on-shelf BUT high velocity + inventory near reorder point
      CHRONIC_OOS   → off-shelf on ≥50% of the days scanned in the last 14 days
      OK            → on-shelf and no risk indicators

    Grain: one row per store × product (point-in-time snapshot).

    NOTE: Run the dependent views (vw_osa_daily, vw_sales_summary, vw_inventory_health)
          before creating this view.
*/

CREATE OR ALTER VIEW retail.vw_oos_classification AS
WITH

-- Latest OSA status per store × product (most recent scan date)
latest_osa AS (
    SELECT
        store_id,
        store_name,
        store_type,
        reg_id,
        reg_name,
        prod_id,
        prod_name,
        brand_name,
        sku,
        cat_name,
        depa_name,
        is_perishable,
        on_shelf_flag,
        osa_date,
        scan_count
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY store_id, prod_id
                ORDER BY osa_date DESC
            ) AS rn
        FROM retail.vw_osa_daily
    ) ranked
    WHERE rn = 1
),

-- Chronic pattern: % of days off-shelf in last 14 days
osa_14d AS (
    SELECT
        store_id,
        prod_id,
        COUNT(*)                                            AS days_scanned,
        SUM(CASE WHEN on_shelf_flag = 0 THEN 1 ELSE 0 END) AS days_off_shelf,
        SUM(CASE WHEN on_shelf_flag = 0 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0)                           AS off_shelf_pct_14d
    FROM retail.vw_osa_daily
    WHERE osa_date >= DATEADD(DAY, -14, CAST(GETDATE() AS DATE))
    GROUP BY store_id, prod_id
),

-- Recent sales velocity per store × product (last 7 days)
sales_7d AS (
    SELECT
        store_id,
        prod_id,
        SUM(qty)                AS units_sold_7d,
        COUNT(DISTINCT ord_id)  AS orders_7d,
        SUM(line_total)         AS revenue_7d
    FROM retail.vw_sales_summary
    WHERE order_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
    GROUP BY store_id, prod_id
),

-- Avg velocity across all store × product combos (for relative comparison)
avg_velocity AS (
    SELECT
        AVG(CAST(units_sold_7d AS FLOAT)) AS avg_units_7d
    FROM sales_7d
),

-- Inventory presence: does a warehouse in the same region carry this product?
inv_exists AS (
    SELECT DISTINCT
        ih.reg_id,
        ih.prod_id,
        ih.safety_stock_qty,
        ih.reorder_point_qty,
        ih.lead_time_days
    FROM retail.vw_inventory_health ih
    WHERE ih.is_discontinued = 0
)

SELECT
    lo.store_id,
    lo.store_name,
    lo.store_type,
    lo.reg_id,
    lo.reg_name,
    lo.prod_id,
    lo.prod_name,
    lo.brand_name,
    lo.sku,
    lo.cat_name,
    lo.depa_name,
    lo.is_perishable,

    -- Latest shelf status
    lo.osa_date                                     AS last_scan_date,
    lo.on_shelf_flag                                AS is_on_shelf,
    lo.scan_count,

    -- 14-day pattern
    COALESCE(o14.days_scanned, 0)                   AS days_scanned_14d,
    COALESCE(o14.days_off_shelf, 0)                 AS days_off_shelf_14d,
    COALESCE(o14.off_shelf_pct_14d, 0)              AS off_shelf_pct_14d,

    -- Recent sales
    COALESCE(s7.units_sold_7d, 0)                   AS units_sold_7d,
    COALESCE(s7.orders_7d, 0)                       AS orders_7d,
    COALESCE(s7.revenue_7d, 0)                      AS revenue_7d,

    -- Inventory params (from regional warehouse)
    ie.safety_stock_qty,
    ie.reorder_point_qty,
    ie.lead_time_days,
    CASE WHEN ie.prod_id IS NOT NULL THEN 1 ELSE 0 END
                                                    AS has_warehouse_inventory,

    -- ═══════════════════════════════════════════
    -- OOS Classification
    -- ═══════════════════════════════════════════
    CASE
        -- CHRONIC: off-shelf ≥50% of last 14 days (check first, most severe pattern)
        WHEN COALESCE(o14.off_shelf_pct_14d, 0) >= 50
         AND COALESCE(o14.days_scanned, 0) >= 3
        THEN 'CHRONIC_OOS'

        -- TRUE OOS: off-shelf now AND no sales in 7 days
        WHEN lo.on_shelf_flag = 0
         AND COALESCE(s7.units_sold_7d, 0) = 0
        THEN 'TRUE_OOS'

        -- PHANTOM OOS: off-shelf now BUT warehouse says inventory exists
        WHEN lo.on_shelf_flag = 0
         AND ie.prod_id IS NOT NULL
         AND COALESCE(s7.units_sold_7d, 0) > 0
        THEN 'PHANTOM_OOS'

        -- AT-RISK: on-shelf BUT selling fast (≥2× avg velocity)
        WHEN lo.on_shelf_flag = 1
         AND COALESCE(s7.units_sold_7d, 0) >= 2 * COALESCE(av.avg_units_7d, 1)
        THEN 'AT_RISK_OOS'

        ELSE 'OK'
    END                                             AS oos_classification

FROM      latest_osa       lo
LEFT JOIN osa_14d          o14  ON o14.store_id = lo.store_id AND o14.prod_id = lo.prod_id
LEFT JOIN sales_7d         s7   ON s7.store_id  = lo.store_id AND s7.prod_id  = lo.prod_id
LEFT JOIN inv_exists       ie   ON ie.reg_id    = lo.reg_id   AND ie.prod_id  = lo.prod_id
CROSS JOIN avg_velocity    av;
GO
