{{ config(materialized='table') }}

with heim_ids as (

    select distinct
        adr_heim
    from {{ ref('bronze_adresse') }}
    where adr_heim is not null

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name
    from {{ ref('bronze_adresse') }}

),

silver_heim as (

    select distinct
        heim_ids.adr_heim          as heim_id,
        adressen.adr_name          as heim_name
    from heim_ids
    left join adressen
        on heim_ids.adr_heim = adressen.adr_adressnummer

)

select *
from silver_heim