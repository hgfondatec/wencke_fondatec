{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT

        36 as mandant,
        bed_60_3 as bed_id,
        bed_1040_30 as bed_name

    FROM {{ source('raw', 'm36bediener') }}


)

SELECT *
FROM bediener