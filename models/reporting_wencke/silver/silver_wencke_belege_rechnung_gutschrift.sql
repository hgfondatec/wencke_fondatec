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
    bel_date,
    bel_project_nr,
    bel_oe_5,
    bel_beleg_bonus,

    CASE
        WHEN bel_project_nr is not null 
            THEN bel_oe_5
        ELSE bel_adr_nr
    END AS bel_final_adr_nr,

    CONCAT(
        COALESCE(bel_art, ''),
        COALESCE(bel_beleg_gruppe, '')
    ) AS bg_beleggruppe

FROM {{ ref('bronze_wencke_belege') }}

WHERE bel_date >= DATE '2025-01-01'
  AND bel_date < DATE '2027-01-01'
  AND bel_art IN ('R', 'G')
  AND bel_status = 'N'