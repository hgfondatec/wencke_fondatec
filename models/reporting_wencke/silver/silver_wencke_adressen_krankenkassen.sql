{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH pflegekassen AS (

    SELECT DISTINCT
        hc.pflegekasse,
        a.mandant
    FROM {{ ref('bronze_wencke_adressen_healthcare') }} AS hc
    INNER JOIN {{ ref('bronze_wencke_adressen') }} AS a
        ON hc.wencke_id = a.wencke_id
    WHERE hc.pflegekasse IS NOT NULL

)

SELECT
    adr.wencke_id,
    pk.mandant,
    adr.adr_nr,
    adr.adr_firmenname,
    CONCAT(
        adr.adr_nr,
        '-',
        COALESCE(adr.adr_firmenname, 'keine Bezeichnung')
    ) AS pflegekasse_text
FROM pflegekassen AS pk
LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS adr
    ON pk.pflegekasse = adr.adr_nr
    AND pk.mandant = adr.mandant