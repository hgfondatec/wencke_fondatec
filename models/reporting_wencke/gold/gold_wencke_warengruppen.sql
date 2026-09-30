{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT DISTINCT
    wg_nr,
    wg_bezeichnung

FROM {{ ref('bronze_wencke_warengruppen') }}

WHERE wg_nr IS NOT NULL