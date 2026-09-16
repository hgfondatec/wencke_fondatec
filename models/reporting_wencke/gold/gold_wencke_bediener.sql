{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT
        *
    FROM {{ ref('bronze_wencke_bediener') }}

)

SELECT

    *,

    CONCAT(
        COALESCE(bed_id::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS bed_key

FROM bediener