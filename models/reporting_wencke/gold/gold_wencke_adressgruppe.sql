{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH adr_gruppe AS (

    SELECT 
        *,

        CONCAT(adrgruppe_id, '-', adrgruppe_name) AS adr_adressgruppe_name,

        CONCAT(
            COALESCE(adrgruppe_id::text, ''),
            '_',
            COALESCE(adrgruppe_mandant::text, '')
        ) AS adr_adressgruppe_key

    FROM {{ ref('bronze_wencke_adressen_adressgruppe') }}

)

SELECT
    *
FROM adr_gruppe