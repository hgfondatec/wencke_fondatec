{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    internal_id,
    wencke_id,
    mandant,
    bel_status,
    bel_nr,
    bel_steuer_art,
    bel_art,
    bel_beleg_gruppe,
    bel_adr_nr,
    bel_vertreter_nr,
    bel_date,
    bel_project_nr,
    bel_oe_5
FROM {{ source('raw', 'wencke_lv_belege') }}