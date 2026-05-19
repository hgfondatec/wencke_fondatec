{{ config(materialized='table') }}

with belege as (
    select 
        *
    from {{ ref('bronze_belege') }}
)

select 
    belege.bel_belegnummer as auftrag_beleg_nr,
    belege.bel_lieferschein_nr as auftrag_lieferschein_nr,
    belege.bel_belegdatum as auftrag_bel_datum,
    belege.bel_beleggruppe as auftrag_beleggruppe,
    belege.bel_belegart as auftrag_belegart,
    belege.bel_adressnummer as auftrag_adress_nr

    from belege
    where belege.bel_belegart = 'A'
    order by belege.bel_belegnummer
