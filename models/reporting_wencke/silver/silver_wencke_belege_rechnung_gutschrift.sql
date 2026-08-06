{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    b.wencke_id,
    b.mandant,
    b.bel_status,
    b.bel_nr,
    b.bel_steuer_art,
    b.bel_art,
    b.bel_beleg_gruppe,
    b.bel_adr_nr,
    b.bel_vertreter_nr,
    b.bel_date,
    b.bel_project_nr,
    b.bel_oe_5,
    b.bel_beleg_bonus,

    br.rezept_variante,

    CASE
        WHEN b.bel_project_nr is not null 
            THEN b.bel_oe_5
        ELSE b.bel_adr_nr
    END AS bel_final_adr_nr,

    CONCAT(
        COALESCE(b.bel_art, ''),
        COALESCE(b.bel_beleg_gruppe, '')
    ) AS bg_beleggruppe 

FROM {{ ref('bronze_wencke_belege') }} b

LEFT JOIN {{ ref('bronze_wencke_belege_rezept') }} br
    ON b.wencke_id = br.wencke_id

WHERE bel_date >= DATE '2025-01-01'
  AND bel_date < DATE '2027-01-01'
  AND bel_art IN ('R', 'G')
  AND bel_status = 'N'