/*  vw_osa_daily
    ────────────
    Enriches daily on-shelf-availability scans with product, store, and region
    dimensions. Enables trend analysis of shelf availability by store, product,
    category, and region over time.

    Grain: one row per store × product × date.
*/

CREATE OR ALTER VIEW retail.vw_osa_daily AS
SELECT
    -- Date
    v.date                                          AS osa_date,

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

    -- Category
    pc.prod_cat_id,
    pc.cat_name,
    pc.depa_name,
    pc.is_peri                                      AS is_perishable,

    -- OSA metrics
    v.scan_count,
    v.on_shelf_flag

FROM      retail.visual_osa_daily     v
JOIN      retail.products             p   ON p.prod_id      = v.prod_id
JOIN      retail.product_categories   pc  ON pc.prod_cat_id = p.prod_cat_id
JOIN      retail.stores               s   ON s.str_id       = v.str_id
JOIN      retail.regions              r   ON r.reg_id       = s.reg_id;
GO
