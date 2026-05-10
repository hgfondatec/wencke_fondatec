{{ config(materialized='table') }}

with patientenkasse_ids as (

    select distinct
        adr_patientenkasse
    from {{ ref('bronze_adresse') }}
    where adr_patientenkasse is not null

),

adressen as (

    select distinct
        adr_adressnummer,
        adr_name
    from {{ ref('bronze_adresse') }}

),

silver_patientenkasse as (

    select distinct
        patientenkasse_ids.adr_patientenkasse          as patientenkasse_id,
        adressen.adr_name                              as patientenkasse_name
    from patientenkasse_ids
    left join adressen
        on patientenkasse_ids.adr_patientenkasse = adressen.adr_adressnummer

)

select *
from silver_patientenkasse