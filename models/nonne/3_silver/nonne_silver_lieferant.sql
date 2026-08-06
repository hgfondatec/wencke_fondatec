{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with lieferant_ids as (

    select distinct
        art_standardlieferantnummer
    from {{ ref('nonne_bronze_artikel') }}
    where art_standardlieferantnummer is not null

),

adressen as (

    select distinct
        TRIM(adr_adressnummer) as adr_adressnummer,
        COALESCE(adr_name, 'keine Bezeichnung') AS adr_name
    from {{ ref('nonne_bronze_adresse') }}

),

silver_lieferant as (

    select distinct
        lieferant_ids.art_standardlieferantnummer          as art_standardlieferantnummer,
        adressen.adr_name                                  as adr_standardlieferantname
    from lieferant_ids
    left join adressen
        on CAST(TRIM(lieferant_ids.art_standardlieferantnummer) AS text) = adressen.adr_adressnummer
    order by lieferant_ids.art_standardlieferantnummer

)

select *
from silver_lieferant