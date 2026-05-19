{{ 
    config(
        materialized='table'
    ) 
}}

with auftrag as (
    select *
    from {{ ref('silver_auftrag_belege') }} 
    where auftrag_beleggruppe is not null 
),

lieferung as (
    select *
    from {{ ref('silver_lieferung_belege') }}
    where lieferung_beleggruppe is not null 
),

rechnung as (
    select *
    from {{ ref('silver_rechnung_belege') }}
    where rechnung_beleggruppe is not null 
),

beleggruppe as (
    select *
    from {{ ref('bronze_beleggruppe') }}
),

beleggruppe_mapping as (
    select *
    from {{ ref('raw_beleg_gruppe') }}
)

select 
    auftrag.auftrag_beleg_nr,
    lieferung.lieferung_beleg_nr,
    rechnung.rechnung_beleg_nr,

    auftrag.auftrag_bel_datum,
    lieferung.lieferung_bel_datum,
    rechnung.rechnnung_bel_datum,

    _position_auftrag.bel_adressnummer as auftrag_adress_nr,
    _position_lieferung.bel_adressnummer as lieferung_adress_nr,
    _position_rechnung.bel_adressnummer as rechnung_adress_nr,

    _position_auftrag.pos_artikelnummer as auftrag_artikel_nr,
    _position_lieferung.pos_artikelnummer as lieferung_artikel_nr,
    _position_rechnung.pos_artikelnummer as rechnung_artikel_nr,

    _beleggruppe_auftrag.bg_beleggruppe as auftrag_beleggruppe,
    _beleggruppe_lieferung.bg_beleggruppe as lieferung_beleggruppe,
    _beleggruppe_rechnung.bg_beleggruppe as rechnung_beleggruppe,

    _beleggruppe_mapping_auftrag."BG_Beleggruppe" as auftrag_beleggruppe_name,
    _beleggruppe_mapping_lieferung."BG_Beleggruppe" as lieferung_beleggruppe_name,
    _beleggruppe_mapping_rechnung."BG_Beleggruppe" as rechnung_beleggruppe_name,

    CASE 
        when _beleggruppe_rechnung.bg_beleggruppe IN ('G00','G01','G02','R00','R83') then 'ja'
        else 'nein'
    end as umsatzrelevant,

    _position_auftrag.pos_gesamtmenge as auftrag_gesamtmenge,
    _position_lieferung.pos_gesamtmenge as lieferung_gesamtmenge,
    _position_rechnung.pos_gesamtmenge as rechnung_gesamtmenge,

    _position_auftrag.pos_gesamtumsatz as auftrag_gesamtumsatz,
    _position_lieferung.pos_gesamtumsatz as lieferung_gesamtumsatz,
    _position_rechnung.pos_gesamtumsatz as rechnung_gesamtumsatz,

    _position_auftrag.pos_gesamtrohertrag as auftrag_gesamtrohertrag,
    _position_lieferung.pos_gesamtrohertrag as lieferung_gesamtrohertrag,
    _position_rechnung.pos_gesamtrohertrag as rechnung_gesamtrohertrag,

    _position_auftrag.pos_ek_einzeln as auftrag_ek_einzeln,
    _position_lieferung.pos_ek_einzeln as lieferung_ek_einzeln,
    _position_rechnung.pos_ek_einzeln as rechnung_ek_einzeln,

    _position_auftrag.bel_vertreter

from auftrag

left join lieferung 
    on auftrag.auftrag_beleg_nr = lieferung.lieferung_interne_beleg_nr

left join rechnung 
    on rechnung.rechnung_lieferschein_nr = lieferung.lieferung_beleg_nr 
    and rechnung.rechnung_interne_beleg_nr = auftrag.auftrag_beleg_nr

left join position _position_auftrag
    on _position_auftrag.bel_belegnummer = auftrag.auftrag_beleg_nr 

left join position _position_lieferung
    on lieferung.lieferung_beleg_nr = _position_lieferung.bel_belegnummer 
    and _position_auftrag.pos_artikelnummer =  _position_lieferung.pos_artikelnummer

left join position _position_rechnung
    on rechnung.rechnung_beleg_nr = _position_rechnung.bel_belegnummer 
    and _position_auftrag.pos_artikelnummer =  _position_rechnung.pos_artikelnummer 

left join beleggruppe _beleggruppe_auftrag
    on auftrag.auftrag_beleggruppe = _beleggruppe_auftrag.bg_beleggruppe_id 
    and auftrag.auftrag_belegart = _beleggruppe_auftrag.bg_belegart 

left join beleggruppe _beleggruppe_lieferung
    on lieferung.lieferung_beleggruppe = _beleggruppe_lieferung.bg_beleggruppe_id 
    and lieferung.lieferung_belegart = _beleggruppe_lieferung.bg_belegart 

left join beleggruppe _beleggruppe_rechnung
    on rechnung.rechnung_beleggruppe = _beleggruppe_rechnung.bg_beleggruppe_id 
    and rechnung.rechnung_belegart = _beleggruppe_rechnung.bg_belegart 

left join beleggruppe_mapping _beleggruppe_mapping_auftrag
    on _beleggruppe_mapping_auftrag."A_Belegart" = _beleggruppe_auftrag.bg_beleggruppe

left join beleggruppe_mapping _beleggruppe_mapping_lieferung
    on _beleggruppe_mapping_lieferung."A_Belegart" = _beleggruppe_lieferung.bg_beleggruppe

left join beleggruppe_mapping _beleggruppe_mapping_rechnung
    on _beleggruppe_mapping_rechnung."A_Belegart" = _beleggruppe_rechnung.bg_beleggruppe

order by auftrag.auftrag_beleg_nr