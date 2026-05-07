/*  vw_labor_coverage
    ──────────────────
    Enriches associate assignments with store and region dimensions.
    Enables analysis of staffing levels, shift distribution, role mix,
    and productivity metrics per store.

    Grain: one row per associate assignment (store × associate × shift × role).
*/

CREATE OR ALTER VIEW retail.vw_labor_coverage AS
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

FROM      retail.associate_assignments  a
JOIN      retail.stores                 s   ON s.str_id = a.str_id
JOIN      retail.regions                r   ON r.reg_id = s.reg_id;
GO
