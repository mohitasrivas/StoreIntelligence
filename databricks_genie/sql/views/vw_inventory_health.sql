/*  vw_inventory_health  (Databricks SQL)
    ────────────────────
    Joins inventory parameters with product, warehouse, and region dimensions.
    Provides safety-stock and reorder-point context so the agent can identify
    products that may need replenishment.

    Grain: one row per inventory record (product × warehouse).

    NOTE: Replace ${catalog} with your Unity Catalog name before running.
*/

CREATE OR REPLACE VIEW ${catalog}.retail.vw_inventory_health AS
SELECT
    -- Inventory
    i.inv_id,
    i.sfty_stock_qty                                AS safety_stock_qty,
    i.reord_pt_qty                                  AS reorder_point_qty,
    i.lead_t_days                                   AS lead_time_days,

    -- Product
    p.prod_id,
    p.prod_name,
    p.brand_name,
    p.sku,
    p.unit_cost_amt,
    p.is_disc                                       AS is_discontinued,

    -- Category
    pc.prod_cat_id,
    pc.cat_name,
    pc.depa_name,
    pc.is_peri                                      AS is_perishable,
    pc.shelf_life_days,

    -- Warehouse
    w.wh_id,
    w.wh_name,
    w.city_name                                     AS wh_city,
    w.state_or_prov                                 AS wh_state,
    w.is_cross_dock,

    -- Region
    r.reg_id,
    r.reg_name,
    r.is_cold_chain_requ                            AS is_cold_chain_required,

    -- Demand signal (if linked via product + region)
    ds.dem_signal_id,
    ds.dem_chn                                      AS demand_channel,
    ds.signal_src_sys                               AS signal_source_system,

    -- Forecast metadata (if linked via product + region)
    f.fcst_id,
    f.fcst_hor_days                                 AS forecast_horizon_days,
    f.fcst_mdl_name                                 AS forecast_model_name,

    -- Risk flags
    CASE WHEN p.is_disc = 1
         THEN 'DISCONTINUED'
         WHEN pc.is_peri = 1 AND i.lead_t_days > pc.shelf_life_days
         THEN 'PERISHABLE_LEAD_TIME_RISK'
         ELSE 'OK'
    END                                             AS risk_flag

FROM      ${catalog}.retail.inventories        i
JOIN      ${catalog}.retail.products           p   ON p.prod_id      = i.prod_id
JOIN      ${catalog}.retail.product_categories pc  ON pc.prod_cat_id = p.prod_cat_id
JOIN      ${catalog}.retail.warehouses         w   ON w.wh_id        = i.wh_id
JOIN      ${catalog}.retail.regions            r   ON r.reg_id       = i.reg_id
LEFT JOIN ${catalog}.retail.demand_signals     ds  ON ds.prod_id     = i.prod_id
                                                  AND ds.reg_id      = i.reg_id
LEFT JOIN ${catalog}.retail.forecasts          f   ON f.prod_id      = i.prod_id
                                                  AND f.reg_id       = i.reg_id;
