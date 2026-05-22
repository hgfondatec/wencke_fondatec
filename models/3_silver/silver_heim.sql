{{ config(materialized='table') }}

with heim_ids as (

    select distinct
        adr_heim
    from {{ ref('bronze_adresse') }}
    where adr_heim <> ''

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name,
        adr_praesident
    from {{ ref('bronze_adresse') }}

),

praesident as (
    select distinct
        praesident_id,
        praesident_bezeichnung,
        praesident_next_level
    from {{ ref('prep_praesident') }}

),

silver_heim as (

    select distinct
        heim_ids.adr_heim          as heim_id,
        adressen.adr_name          as heim_name,

        coalesce(cast(heim_ids.adr_heim as varchar(10)), 'XX') || '-' ||  coalesce(adressen.adr_name, 'keine Bezeichnung') as heim_bezeichnung,

        p3.praesident_bezeichnung as heim_praesident_3,
        p2.praesident_bezeichnung as heim_praesident_2,
        p1.praesident_bezeichnung as heim_praesident_1

    from heim_ids

    left join adressen
        on heim_ids.adr_heim = adressen.adr_adressnummer

    left join praesident p3
        on adressen.adr_praesident = p3.praesident_id

    left join praesident p2
        on p3.praesident_next_level = p2.praesident_id

    left join praesident p1
        on p2.praesident_next_level = p1.praesident_id

)

select *
from silver_heim