{{ config(materialized='table') }}

with belege as (
    select 
        *
    from {{ ref('nonne_bronze_belege') }}
)

select 
    belege.bel_belegnummer as rekla_beleg_nr,
    belege.bel_urbeleg_nr as rekla_urbeleg_nr,
    belege.bel_belegdatum as rekla_bel_datum,
    belege.bel_beleggruppe as rekla_beleggruppe,
    belege.bel_belegart as rekla_belegart,
    belege.bel_projektnummer rekla_projektnummer,
    belege.bel_adressnummer as rekla_adressnummer,
    belege.bel_heim as rekla_heim

    from belege
    where belege.bel_belegart in ('I') and belege.bel_beleggruppe = '65' 
    order by belege.bel_belegnummer
