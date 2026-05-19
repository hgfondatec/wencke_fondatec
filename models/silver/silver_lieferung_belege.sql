{{ config(materialized='table') }}

with belege as (
    select 
        *
    from {{ ref('bronze_belege') }}
)

select 
    belege.bel_belegnummer as lieferung_beleg_nr,
    belege.bel_interne_belegnummer as lieferung_interne_beleg_nr,
    belege.bel_belegdatum as lieferung_bel_datum,
    belege.bel_liefer_termindatum as lieferung_termindatum,
    belege.bel_beleggruppe as lieferung_beleggruppe,
    belege.bel_belegart as lieferung_belegart,
    belege.bel_adressnummer as lieferung_adress_nr

    from belege
    where belege.bel_belegart = 'L'
    order by belege.bel_belegnummer
