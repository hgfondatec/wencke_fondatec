{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}


with belege as (

    select distinct
        bel_belegnummer,
        bel_adressnummer,
        bel_belegart
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


beleggruppe as (

    select
        bg_beleggruppe,
        bg_belegart,
        bg_beleggruppe_id,
        "BG_Beleggruppe"
    from {{ ref('silver_beleggruppe') }}

)

select
    belege.bel_belegnummer,
    belege.bel_adressnummer,
    belege.bel_belegart,

    beleggruppe.bg_beleggruppe,
    beleggruppe."BG_Beleggruppe",
    CASE 
        when beleggruppe.bg_beleggruppe IN ('G00','G01','G02','R00','R83') then 'ja'
        else 'nein'
    end as umsatzrelevant,

    positionen.pos_artikelnummer,
    positionen.pos_gesamtmenge,
    positionen.pos_gesamtumsatz,
    positionen.pos_gesamtrohertrag,
    positionen.pos_ek_einzeln

from belege

left join positionen
    on CAST(positionen.pos_belegnummer as varchar(12)) = belege.bel_belegnummer


left join beleggruppe
    on LPAD(beleggruppe.bg_beleggruppe_id::varchar, 2, '0') = belege.bel_beleggruppe
    and beleggruppe.bg_belegart = belege.bel_belegart

order by
    belege.bel_belegdatum,
    belege.bel_belegnummer