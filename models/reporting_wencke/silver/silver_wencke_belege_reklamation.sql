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

    CASE
        WHEN b.bel_project_nr is not null 
            THEN b.bel_oe_5
        ELSE b.bel_adr_nr
    END AS bel_final_adr_nr,

    CONCAT(
        COALESCE(b.bel_art, ''),
        COALESCE(b.bel_beleg_gruppe, '')
    ) AS bg_beleggruppe,

    br.ur_reklamation_index

FROM {{ ref('bronze_wencke_belege') }} b

LEFT JOIN {{ ref('bronze_wencke_belege_reklamation') }} br
    on b.wencke_id = br.wencke_id

WHERE b.bel_date >= DATE '2025-01-01'
  AND b.bel_date < DATE '2027-01-01'
  AND b.bel_art IN ('I')
  AND b.bel_beleg_gruppe IN ('65')
  AND b.bel_status = 'N'