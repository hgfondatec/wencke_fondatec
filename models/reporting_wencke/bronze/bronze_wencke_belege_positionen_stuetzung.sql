{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id, 
    ausgleich_akt_ek, 
    stuetzung_gesamt, 
    vorgabe_prozent_euro

FROM {{ source('raw', 'wencke_lv_belege_positionen_stuetzung') }}