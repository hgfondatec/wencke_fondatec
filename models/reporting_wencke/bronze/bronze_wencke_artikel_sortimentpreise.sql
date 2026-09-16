{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH sortimentpreise AS (

    SELECT

         36 as mandant,
        idbid0201_50_25 as artikel,
        idbid0201_76_8 as adr_nr,

        CASE
             WHEN idbid0201_84_10 < DATE '1900-01-01' THEN NULL
             ELSE idbid0201_84_10
        END AS gueltig_ab,

        CASE
             WHEN idbid0201_94_10 < DATE '1900-01-01' THEN NULL
             ELSE idbid0201_94_10
        END AS gueltig_bis,

        idbid0201_323_8 as stuetungswert,
        idbid0201_331_10 as datum_bis_gerettet,
        idbid0201_372_8 as FAP_aktuell

    FROM {{ source('raw', 'm36stupre') }}


)

SELECT *
FROM sortimentpreise