{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH ekv AS (
    
    SELECT DISTINCT
        *,
        CONCAT(
            COALESCE(adr_nr::text, ''),
            '_',
            COALESCE(ekv_mandant::text, '')
        ) AS ekv_adress_key
    FROM {{ ref('bronze_wencke_adressen_ekv') }}
    WHERE ekv_aktiv IS TRUE
)

SELECT *
FROM ekv