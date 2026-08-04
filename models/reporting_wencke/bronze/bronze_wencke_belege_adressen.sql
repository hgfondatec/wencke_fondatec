{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    adr_typ,
    adr_kurzname,
    adr_anrede,
    adr_vorname,
    adr_nachname,
    adr_name1,
    adr_name2,
    adr_name3,
    adr_strasse,
    adr_hausnr,
    adr_plz,
    adr_ort
FROM {{ source('raw', 'wencke_lv_belege_adressen') }}