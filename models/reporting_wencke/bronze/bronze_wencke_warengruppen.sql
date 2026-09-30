{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT

    wencke_id,
    mandant,
    wg_nr

FROM {{ source('raw', 'wencke_lv_warengruppen') }}