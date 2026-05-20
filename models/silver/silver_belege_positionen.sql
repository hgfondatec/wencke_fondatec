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
        bel_vertreter,
        bel_beleggruppe
    from {{ ref('bronze_belege') }}
    where bel_beleggruppe is not null and bel_belegart in ('A','L','R','G')

),

positionen as (

    select
        pos_belegnummer,
        pos_artikelnummer,
        pos_ek_einzeln as pos_ek_einzeln,
        pos_gesamtrohertrag as pos_gesamtrohertrag,
        pos_gesamtumsatz as pos_gesamtumsatz,
        pos_gesamtmenge as pos_gesamtmenge
    from {{ ref('bronze_positionen') }}
    where pos_artikelnummer <> '' and pos_artikelnummer is not null and pos_belegart in ('A','L','R','G')

    UNION ALL 

    SELECT 
        * 
    from {{ ref('silver_nebenkosten') }} 

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

),

beleggruppe as (

    select
        bg_beleggruppe,
        bg_belegart,
        bg_beleggruppe_id
    from {{ ref('bronze_beleggruppe') }}

)

select
    belege.bel_belegnummer,
    belege.bel_belegdatum,
    belege.bel_adressnummer,
    belege.bel_belegart,
    beleg_arten.bel_belegname,
    belege.bel_vertreter,

    beleggruppe.bg_beleggruppe,
    CASE 
        when beleggruppe.bg_beleggruppe IN ('G00','G01','G02','R00','R83') then 'ja'
        else 'nein'
    end as umsatzrelevant,

    vertreter.ver_vertretername,

    positionen.pos_artikelnummer,
    positionen.pos_gesamtmenge,
    positionen.pos_gesamtumsatz,
    positionen.pos_gesamtrohertrag,
    positionen.pos_ek_einzeln

from belege

left join positionen
    on CAST(positionen.pos_belegnummer as varchar(12)) = belege.bel_belegnummer

left join beleg_arten
    on beleg_arten.bel_belegart = belege.bel_belegart

left join vertreter
    on CAST(vertreter.ver_vertreternummer as varchar(12)) = belege.bel_vertreter

left join beleggruppe
    on CAST(beleggruppe.bg_beleggruppe_id as varchar(12)) = belege.bel_beleggruppe
    and beleggruppe.bg_belegart = belege.bel_belegart

order by
    belege.bel_belegdatum,
    belege.bel_belegnummer