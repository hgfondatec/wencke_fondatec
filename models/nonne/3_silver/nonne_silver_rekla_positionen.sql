{{ config(materialized='table') }}

with positionen as (
    select
        pos_belegnummer,
        pos_artikelnummer,
        pos_positionsnummer,
        pos_artikeltext,
        pos_rekla_information,
        pos_rekla_verursacher,
        pos_rekla_massnahme
    from {{ ref('nonne_bronze_positionen') }}
    where pos_zeilenstatus = '0'
)

select 
    *
from positionen
