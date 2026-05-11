{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}


with belege as (

    select distinct
        bel_belegnummer,
        bel_belegdatum,
        bel_adressnummer,
        bel_belegart,
        bel_vertreter
    from {{ ref('bronze_belege') }}

),

positionen as (

    select
        pos_belegnummer,
        pos_artikelnummer,
        pos_artikeltext,
        sum(pos_gesamtmenge) as pos_gesamtmenge,
        sum(pos_gesamtumsatz_vor_bonus) as pos_gesamtumsatz_vor_bonus,
        sum(pos_rohertrag_verrechnet) as pos_rohertrag_verrechnet,
        sum(pos_rohertrag_vor_bonus) as pos_rohertrag_vor_bonus,
        sum(pos_umsatz_bonus_vorlaeufig) as pos_umsatz_bonus_vorlaeufig,
        sum(pos_umsatz_bonus_endgueltig) as pos_umsatz_bonus_endgueltig
    from {{ ref('bronze_positionen') }}
    group by
        pos_belegnummer,
        pos_artikelnummer,
        pos_artikeltext

),

beleg_arten as (

    select
        bel_belegart,
        bel_belegname
    from {{ ref('raw_beleg_arten') }}

),

vertreter as (

    select
        ver_vertreternummer,
        ver_vertretername
    from {{ ref('raw_vertreter') }}

)

select
    belege.bel_belegnummer,
    belege.bel_belegdatum,
    belege.bel_adressnummer,
    belege.bel_belegart,
    beleg_arten.bel_belegname,
    belege.bel_vertreter,

    vertreter.ver_vertretername,

    positionen.pos_artikelnummer,
    positionen.pos_artikeltext,
    positionen.pos_gesamtmenge,
    positionen.pos_gesamtumsatz_vor_bonus,
    positionen.pos_rohertrag_verrechnet,
    positionen.pos_rohertrag_vor_bonus,
    positionen.pos_umsatz_bonus_vorlaeufig,
    positionen.pos_umsatz_bonus_endgueltig

from belege

left join positionen
    on positionen.pos_belegnummer = belege.bel_belegnummer

left join beleg_arten
    on beleg_arten.bel_belegart = belege.bel_belegart

left join vertreter
    on vertreter.ver_vertreternummer = belege.bel_vertreter

order by
    belege.bel_belegdatum,
    belege.bel_belegnummer