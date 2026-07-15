{{ config(materialized='table') }}

with belege as (
    select 
        *
    from {{ ref('glasofix_bronze_belege') }}
)

select 
    belege.bel_belegnummer as rechnung_beleg_nr,
    belege.bel_lieferschein_nr as rechnung_lieferschein_nr,
    belege.bel_blfanummer as rechnung_blfa_nr,
    belege.bel_interne_belegnummer as rechnung_interne_beleg_nr,
    belege.bel_belegdatum as rechnung_bel_datum,
    belege.bel_beleggruppe as rechnung_beleggruppe,
    belege.bel_belegart as rechnung_belegart,
    belege.bel_projektnummer rechnung_projektnummer,
    belege.bel_steuerart as rechnung_steuerart,
    belege.bel_bonusbeleg as rechnung_bonusbelege_flag,
    belege.bel_adressnummer as rechnung_adressnummer,
    belege.bel_heim as rechnung_heim


    from belege
    where belege.bel_belegart IN('R','G') and belege.bel_belegstatus_a_n ='N'
    order by belege.bel_belegnummer
