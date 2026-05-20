{{ config(materialized='table') }}

with belege as (
    select 
        *
    from {{ ref('bronze_belege') }}
)

select 
    belege.bel_belegnummer as rechnung_beleg_nr,
    belege.bel_lieferschein_nr as rechnung_lieferschein_nr,
    belege.bel_interne_belegnummer as rechnung_interne_beleg_nr,
    belege.bel_belegdatum as rechnnung_bel_datum,
    belege.bel_beleggruppe as rechnung_beleggruppe,
    belege.bel_belegart as rechnung_belegart,
    belege.bel_adressnummer as rechnung_adress_nr,
    belege.bel_steuerart as rechnung_steuerart

    from belege
    where belege.bel_belegart IN('R','G') and belege.bel_belegstatus_a_n ='N'
    order by belege.bel_belegnummer
