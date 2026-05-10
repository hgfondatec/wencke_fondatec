{{ config(materialized='table') }}

with adresse as (
    select 
        *
    from {{ ref('bronze_adresse') }}
),
adresstypen as (
    select 
        *
    from {{ ref('bronze_adresstypen') }}
)

select 
    adresse.adr_adressnummer,
    adresse.adr_name,
    adresse.adr_adresse,
    adresse.adr_plz,
    adresse.adr_stadt,
    adresse.adr_nummer
    from adresse
    order by adresse.adr_adressnummer
