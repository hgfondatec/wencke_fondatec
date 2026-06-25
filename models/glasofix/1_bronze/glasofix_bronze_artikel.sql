{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with source_data as (

    select distinct
        art_1_25    as art_artikelnummer,
        art_51_60   as art_artikelname,
        art_870_40  as art_bezeichnung_2,
        art_910_40  as art_bezeichnung_3,
        art_950_40  as art_bezeichnung_4,
        art_41_2    as art_hauptkategorie_id,
        art_41_5    as art_nebenkategorie_id,
        art_138_8   as art_standardlieferantnummer,
        art_178_9   as art_ek_netto,
        art_1072_25 as art_herstellernummer,
        art_1706_5  as art_lagereinheit,
        art_1940_1  as art_abc_kategorie,
        art_2582_1  as art_divers_flag
    from {{ source('raw', 'm39art') }}

)

select
    *
from source_data