/*  vw_sales_summary
    ─────────────────
    Aggregates order + line-item data by store, region, date, product, and category.
    Grain: one row per order line (store × order × product).
*/

CREATE OR ALTER VIEW retail.vw_sales_summary AS
SELECT
    -- Date
    CAST(o.ord_dt AS DATE)                          AS order_date,

    -- Store
    s.str_id                                        AS store_id,
    s.str_name                                      AS store_name,
    s.str_type                                      AS store_type,

    -- Region
    r.reg_id,
    r.reg_name,

    -- Product
    p.prod_id,
    p.prod_name,
    p.brand_name,
    p.sku,
    p.unit_cost_amt,

    -- Category
    pc.prod_cat_id,
    pc.cat_name,
    pc.depa_name,
    pc.is_peri,

    -- Order header
    o.ord_id,
    o.ord_status,
    o.is_expe                                       AS is_expedited,
    o.ord_total_amt,
    o.paym_method_type,

    -- Line metrics
    ol.qty,
    ol.unit_price_amt,
    ol.ln_total_amt                                  AS line_total,

    -- Derived: margin per line
    (ol.unit_price_amt - p.unit_cost_amt) * ol.qty   AS line_margin_amt

FROM      retail.orders           o
JOIN      retail.order_lines      ol  ON ol.ord_id    = o.ord_id
JOIN      retail.products         p   ON p.prod_id    = ol.prod_id
JOIN      retail.product_categories pc ON pc.prod_cat_id = p.prod_cat_id
JOIN      retail.stores           s   ON s.str_id     = o.str_id
JOIN      retail.regions          r   ON r.reg_id     = o.reg_id;
GO
