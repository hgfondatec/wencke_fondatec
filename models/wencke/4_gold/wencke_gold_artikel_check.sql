{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with artikel_ids as (

    select art_artikelnummer from {{ ref('glasofix_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('lloyd_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('vms_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('nonne_gold_artikel_v2') }}

),

t39 as (select * from {{ ref('glasofix_gold_artikel') }}),
t32 as (select * from {{ ref('lloyd_gold_artikel') }}),
t42 as (select * from {{ ref('vms_gold_artikel') }}),
t36 as (select * from {{ ref('nonne_gold_artikel_v2') }})

select
    base.art_artikelnummer,

    case when t39.art_artikelnummer is not null then 1 else 0 end as verfuegbar_39,
    case when t32.art_artikelnummer is not null then 1 else 0 end as verfuegbar_32,
    case when t42.art_artikelnummer is not null then 1 else 0 end as verfuegbar_42,
    case when t36.art_artikelnummer is not null then 1 else 0 end as verfuegbar_36,

    case 
        when coalesce(
            t39.art_tos_verfuegbar,
            t32.art_tos_verfuegbar,
            t42.art_tos_verfuegbar,
            t36.art_tos_verfuegbar
        ) = 'J'
        then 'J'
        else 'N'
    end as art_tos_verfuegbar,

    t39.art_artikelname as art_artikelname_39,
    t32.art_artikelname as art_artikelname_32,
    t42.art_artikelname as art_artikelname_42,
    t36.art_artikelname as art_artikelname_36,

    t39.art_bezeichnung as art_bezeichnung_39,
    t32.art_bezeichnung as art_bezeichnung_32,
    t42.art_bezeichnung as art_bezeichnung_42,
    t36.art_bezeichnung as art_bezeichnung_36,

    t39.art_bezeichnung_2 as art_bezeichnung_2_39,
    t32.art_bezeichnung_2 as art_bezeichnung_2_32,
    t42.art_bezeichnung_2 as art_bezeichnung_2_42,
    t36.art_bezeichnung_2 as art_bezeichnung_2_36,

    t39.art_bezeichnung_3 as art_bezeichnung_3_39,
    t32.art_bezeichnung_3 as art_bezeichnung_3_32,
    t42.art_bezeichnung_3 as art_bezeichnung_3_42,
    t36.art_bezeichnung_3 as art_bezeichnung_3_36,

    t39.art_bezeichnung_4 as art_bezeichnung_4_39,
    t32.art_bezeichnung_4 as art_bezeichnung_4_32,
    t42.art_bezeichnung_4 as art_bezeichnung_4_42,
    t36.art_bezeichnung_4 as art_bezeichnung_4_36,

    t39.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_39,
    t32.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_32,
    t42.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_42,
    t36.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_36,

    t39.art_hauptwarengruppe as art_hauptwarengruppe_39,
    t32.art_hauptwarengruppe as art_hauptwarengruppe_32,
    t42.art_hauptwarengruppe as art_hauptwarengruppe_42,
    t36.art_hauptwarengruppe as art_hauptwarengruppe_36,

    t39.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_39,
    t32.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_32,
    t42.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_42,
    t36.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_36,

    t39.art_nebenwarengruppe_nummer as art_nebenwarengruppe_nummer_39,
    t32.art_nebenwarengruppe_nummer as art_nebenwarengruppe_nummer_32,
    t42.art_nebenwarengruppe_nummer as art_nebenwarengruppe_nummer_42,
    t36.art_nebenwarengruppe_nummer as art_nebenwarengruppe_nummer_36,

    t39.art_nebenwarengruppe as art_nebenwarengruppe_39,
    t32.art_nebenwarengruppe as art_nebenwarengruppe_32,
    t42.art_nebenwarengruppe as art_nebenwarengruppe_42,
    t36.art_nebenwarengruppe as art_nebenwarengruppe_36,

    t39.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_39,
    t32.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_32,
    t42.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_42,
    t36.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_36,

    t39.art_herstellernummer as art_herstellernummer_39,
    t32.art_herstellernummer as art_herstellernummer_32,
    t42.art_herstellernummer as art_herstellernummer_42,
    t36.art_herstellernummer as art_herstellernummer_36,

    t39.art_lieferant as art_lieferant_39,
    t32.art_lieferant as art_lieferant_32,
    t42.art_lieferant as art_lieferant_42,
    t36.art_lieferant as art_lieferant_36,

    t39.art_lieferantbezeichnung as art_lieferantbezeichnung_39,
    t32.art_lieferantbezeichnung as art_lieferantbezeichnung_32,
    t42.art_lieferantbezeichnung as art_lieferantbezeichnung_42,
    t36.art_lieferantbezeichnung as art_lieferantbezeichnung_36,

    t39.art_divers_flag as art_divers_flag_39,
    t32.art_divers_flag as art_divers_flag_32,
    t42.art_divers_flag as art_divers_flag_42,
    t36.art_divers_flag as art_divers_flag_36,

    t39.art_ek_netto as art_ek_netto_39,
    t32.art_ek_netto as art_ek_netto_32,
    t42.art_ek_netto as art_ek_netto_42,
    t36.art_ek_netto as art_ek_netto_36,

    t39.art_lagereinheit as art_lagereinheit_39,
    t32.art_lagereinheit as art_lagereinheit_32,
    t42.art_lagereinheit as art_lagereinheit_42,
    t36.art_lagereinheit as art_lagereinheit_36

from artikel_ids base

left join t39 on base.art_artikelnummer = t39.art_artikelnummer
left join t32 on base.art_artikelnummer = t32.art_artikelnummer
left join t42 on base.art_artikelnummer = t42.art_artikelnummer
left join t36 on base.art_artikelnummer = t36.art_artikelnummer

order by base.art_artikelnummer