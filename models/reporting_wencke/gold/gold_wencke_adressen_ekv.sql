{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH ekv AS (

    SELECT 
        distinct
        *,

        CONCAT(
            COALESCE(adr_nr::text, ''),
            '_',
            COALESCE(ekv_mandant::text, '')
        ) AS ekv_adress_key

    FROM {{ ref('bronze_wencke_adressen_ekv') }}

    where adr_nr <> '' and EXTRACT(year from ekv_datum) = 2999

)

SELECT
    *
FROM ekv