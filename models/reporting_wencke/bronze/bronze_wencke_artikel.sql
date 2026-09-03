{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    artikel_nr

FROM {{ source('raw', 'wencke_lv_artikel') }}