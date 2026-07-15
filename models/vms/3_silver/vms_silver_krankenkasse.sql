{{ config(materialized='table') }}

with krankenkasse as (

    select distinct
        adr_krankenkasse
    from {{ ref('vms_bronze_adresse') }}
    where adr_krankenkasse is not null

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name
    from {{ ref('vms_bronze_adresse') }}

),

silver_krankenkasse as (

    select distinct
        krankenkasse.adr_krankenkasse          as krankenkasse_id,
        adressen.adr_name                      as krankenkasse_name,
        coalesce(cast(krankenkasse.adr_krankenkasse as varchar(10)), 'XX') || '-' ||  coalesce(adressen.adr_name , 'keine Bezeichnung') as krankenkasse_bezeichnung
    from krankenkasse
    left join adressen
        on krankenkasse.adr_krankenkasse = adressen.adr_adressnummer

)

select *
from silver_krankenkasse