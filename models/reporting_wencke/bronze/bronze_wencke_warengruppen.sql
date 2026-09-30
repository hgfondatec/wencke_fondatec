{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT

    wencke_id,
    mandant,
    wg_nr,
    wg_bezeichnung

FROM {{ source('raw', 'wencke_lv_warengruppen') }}