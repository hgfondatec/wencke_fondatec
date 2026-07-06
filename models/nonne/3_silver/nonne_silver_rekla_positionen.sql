{{ config(materialized='table') }}

with positionen as (
    select
        TRIM(pos_belegnummer) as pos_belegnummer,
        pos_artikelnummer,
        pos_positionsnummer,
        pos_artikeltext,
        LTRIM(pos_rekla_grund,'0') as pos_rekla_grund,
        pos_rekla_information,
        pos_rekla_verursacher,
        pos_rekla_massnahme
    from {{ ref('nonne_bronze_positionen') }}
    where pos_zeilenstatus = '0' and pos_rekla_grund <>''
)

select 
    *
from positionen
