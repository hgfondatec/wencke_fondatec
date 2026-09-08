{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    bel_wencke_id,  
    kom_lfd_nr as pos_lfd_nr, 
    kom_text as pos_artikel_text,
    kom_typ

FROM {{ source('raw', 'wencke_lv_belege_positionen_kommentare') }}