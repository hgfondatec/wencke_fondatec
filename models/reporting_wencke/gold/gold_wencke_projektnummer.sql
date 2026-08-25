{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH prj AS (

    SELECT 
        distinct
        *,

        CONCAT(
            COALESCE(prj_lieferant::text, ''),
            '_',
            COALESCE(prj_adr_nr::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS lieferant_adress_mandant_key

    FROM {{ ref('bronze_wencke_projektnummer') }}

    where prj_lieferant is not null and prj_lieferant <> ''

)

SELECT
    *
FROM prj