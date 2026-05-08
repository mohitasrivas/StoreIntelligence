/*  vw_labor_coverage  (Databricks SQL)
    ──────────────────
    Enriches associate assignments with store and region dimensions.
    Enables analysis of staffing levels, shift distribution, role mix,
    and productivity metrics per store.

    Grain: one row per associate assignment (store × associate × shift × role).

    NOTE: Replace ${catalog} with your Unity Catalog name before running.
*/

CREATE OR REPLACE VIEW ${catalog}.retail.vw_labor_coverage AS
SELECT
    -- Store
    s.str_id                                        AS store_id,
    s.str_name                                      AS store_name,
    s.str_type                                      AS store_type,

    -- Region
    r.reg_id,
    r.reg_name,

    -- Assignment
    a.assoc_id                                      AS associate_id,
    a.shift,
    a.role,

    -- Productivity
    a.ords_mng                                      AS orders_managed,
    a.tasks_cplt                                    AS tasks_completed

FROM      ${catalog}.retail.associate_assignments  a
JOIN      ${catalog}.retail.stores                 s   ON s.str_id = a.str_id
JOIN      ${catalog}.retail.regions                r   ON r.reg_id = s.reg_id;
