{{ config(materialized='table') }}

with rechnungsempfaenger_ids as (

    select distinct
        adr_rechnungsempfaenger
    from {{ ref('lloyd_bronze_adresse') }}
    where adr_rechnungsempfaenger is not null

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name
    from {{ ref('lloyd_bronze_adresse') }}

),

silver_rechnungsempfaenger as (

    select distinct
        rechnungsempfaenger_ids.adr_rechnungsempfaenger     as rechnungsempfaenger_id,
        adressen.adr_name                                   as rechnungsempfaenger_name,
        coalesce(cast(rechnungsempfaenger_ids.adr_rechnungsempfaenger as varchar(10)), 'XX') || '-' ||  coalesce(adressen.adr_name, 'keine Bezeichnung') as rechnungsempfaenger_bezeichnung
    from rechnungsempfaenger_ids
    left join adressen
        on rechnungsempfaenger_ids.adr_rechnungsempfaenger = adressen.adr_adressnummer

)

select *
from silver_rechnungsempfaenger