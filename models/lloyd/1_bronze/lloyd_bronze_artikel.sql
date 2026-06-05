{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with source_data as (

    select distinct
        art_1_25 as art_artikelnummer,
        art_51_60 as art_artikelname,
        art_41_2 as art_hauptkategorie_id,
        art_41_5 as art_nebenkategorie_id,
        art_138_8 as art_standardlieferantnummer,
        art_178_9 as art_ek_netto,
        art_1072_25 as art_herstellernummer,
        art_1706_5 as art_lagereinheit,
        art_1940_1 as art_abc_kategorie,
        art_2582_1 as art_divers_flag,
        art_4230_10 as art_bestand_loxstedt,
        art_4290_10 as art_bestand_bremen,
        art_4350_10 as art_bestand_braunschweig,
        art_4410_10 as art_bestand_oldenburg
    from {{ source('raw', 'm32art') }}

)

select
    *
from source_data