{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}


with belege as (

    select distinct
        *
    from {{ ref('prep_rechnung_belege') }}

),

positionen as (

    select
        pos_belegnummer,
        pos_artikelnummer,
        pos_positionsnummer,
        NULLIF(REPLACE(pos_ek_einzeln, ',', '.'), '')::float AS pos_ek_einzeln,
        NULLIF(REPLACE(pos_rohertrag_vor_bonus, ',', '.'), '')::float AS pos_rohertrag_vor_bonus,
        NULLIF(REPLACE(pos_gesamtrohertrag, ',', '.'), '')::float AS pos_gesamtrohertrag,
        NULLIF(REPLACE(pos_gesamtumsatz_vor_bonus, ',', '.'), '')::float AS pos_gesamtumsatz_vor_bonus,
        NULLIF(REPLACE(pos_gesamtumsatz, ',', '.'), '')::float AS pos_gesamtumsatz,
        NULLIF(REPLACE(pos_gesamtmenge, ',', '.'), '')::float AS pos_gesamtmenge
    from {{ ref('bronze_positionen') }}
    where pos_artikelnummer <> '' and pos_artikelnummer is not null and pos_belegart in ('R','G') and pos_beleg_status='N'

    UNION ALL 

    SELECT 
        pos_belegnummer,
        pos_artikelnummer,
        pos_positionsnummer::text,
        pos_ek_einzeln,
        pos_rohertrag_vor_bonus,
        pos_gesamtrohertrag,
        pos_gesamtumsatz_vor_bonus,
        pos_gesamtumsatz,
        pos_gesamtmenge
    from {{ ref('prep_nebenkosten') }} 

),


beleggruppe as (

    select
        bg_beleggruppe,
        bg_belegart,
        bg_beleggruppe_id,
        "BG_Beleggruppe"
    from {{ ref('prep_beleggruppe') }}

)

select
    belege.rechnung_beleg_nr as bel_belegnummer,
    belege.rechnung_bel_datum as bel_belegdatum,
    belege.rechnung_adress_nr as bel_adressnummer,
    belege.rechnung_belegart bel_belegart,
    belege.rechnung_steuerart,
    belege.rechnung_bonusbelege_flag,

    beleggruppe.bg_beleggruppe,
    beleggruppe."BG_Beleggruppe",

    positionen.pos_artikelnummer,
    positionen.pos_positionsnummer,
    positionen.pos_rohertrag_vor_bonus,
    positionen.pos_gesamtmenge,
    positionen.pos_gesamtumsatz_vor_bonus,
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