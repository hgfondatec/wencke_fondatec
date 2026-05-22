{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with lieferant_ids as (

    select distinct
        art_standardlieferantnummer
    from {{ ref('bronze_artikel') }}
    where art_standardlieferantnummer is not null

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name
    from {{ ref('bronze_adresse') }}

),

silver_lieferant as (

    select distinct
        lieferant_ids.art_standardlieferantnummer          as art_standardlieferantnummer,
        adressen.adr_name                                  as adr_standardlieferantname
    from lieferant_ids
    left join adressen
        on lieferant_ids.art_standardlieferantnummer = CAST(adressen.adr_adressnummer AS text)
    order by lieferant_ids.art_standardlieferantnummer

)

select *
from silver_lieferant