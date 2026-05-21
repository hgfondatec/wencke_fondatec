{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}


with belege as (

    select distinct
        *
    from {{ ref('silver_rechnung_belege') }}

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
    where pos_artikelnummer <> '' and pos_artikelnummer is not null and pos_belegart in ('R','G')

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
    belege.rechnung_beleg_nr as bel_belegnummer,
    belege.rechnung_bel_datum as bel_belegdatum,
    belege.rechnung_adress_nr as bel_adressnummer,
    belege.rechnung_belegart bel_belegart,
    belege.rechnung_steuerart,

    beleggruppe.bg_beleggruppe,
    beleggruppe."BG_Beleggruppe",

    positionen.pos_artikelnummer,
    positionen.pos_gesamtmenge,
    positionen.pos_gesamtumsatz,
    positionen.pos_gesamtrohertrag,
    positionen.pos_ek_einzeln

from belege

left join positionen
    on CAST(positionen.pos_belegnummer as varchar(12)) = belege.rechnung_beleg_nr


left join beleggruppe
    on LPAD(beleggruppe.bg_beleggruppe_id::varchar, 2, '0') = belege.rechnung_beleggruppe
    and beleggruppe.bg_belegart = belege.rechnung_belegart

order by
    belege.rechnung_bel_datum,
    belege.rechnung_beleg_nr