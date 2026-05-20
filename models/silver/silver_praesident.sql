{{ config(materialized='table') }}

with praesident_id as (

    select distinct
        adr_praesident
    from {{ ref('bronze_adresse') }}
    where adr_praesident is not null and adr_praesident <> ''

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name,
        adr_praesident
    from {{ ref('bronze_adresse') }}

),

silver_praesident  as (

    select distinct
        praesident_id.adr_praesident          as praesident_id,
        adressen.adr_name                     as praesident_name,
        coalesce(cast(praesident_id.adr_praesident as varchar(10)), 'XX') || '-' ||  coalesce(adressen.adr_name, 'keine Bezeichnung') as praesident_bezeichnung,
        adressen.adr_praesident               as praesident_next_level
    from praesident_id
    left join adressen
        on praesident_id.adr_praesident = adressen.adr_adressnummer

)

select *
from silver_praesident 