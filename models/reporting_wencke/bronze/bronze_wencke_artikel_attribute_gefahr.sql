{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id,
    art_gefahrstoff,
    art_baua_reg_nr,
    art_biozid,
    art_biozid_zulassungsnummer

FROM {{ source('raw', 'wencke_lv_artikel_attribute_gefahr') }}