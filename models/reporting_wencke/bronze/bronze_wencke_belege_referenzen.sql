{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    id, 
    wencke_id, 
    ref_typ, 
    ref_bel_art, 
    ref_bel_nr, 
    ref_date
    
FROM {{ source('raw', 'wencke_lv_belege_referenzen') }}