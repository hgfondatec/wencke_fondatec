{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    mandant,
    bel_status,
    bel_nr,
    bel_steuer_art,
    bel_art,
    bel_beleg_gruppe,
    bel_adr_nr,
    bel_vertreter_nr,
    bel_versand_art,
    bel_nl_nachlieferung,
    bel_date,
    bel_project_nr,
    bel_oe_5,
    bel_beleg_bonus,
    bel_filiale,
    bel_liefernde_filiale,
    bel_lieferschein_nr,
    bel_created_by_user,
    bel_updated_by_user
FROM {{ source('raw', 'wencke_lv_belege') }}