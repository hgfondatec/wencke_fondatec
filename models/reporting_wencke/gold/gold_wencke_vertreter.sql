{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH vertreter AS (

    SELECT 
        *,

        CONCAT(TRIM(ver_vertreternummer), '-', ver_vertretername) AS ver_vertreternummer_name,

        CONCAT(
            COALESCE(ver_vertreternummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS vertreter_key

    FROM {{ ref('bronze_wencke_vertreter') }}

)

SELECT
    *
FROM vertreter