{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with artikel as (
    select *
    from {{ ref('vms_bronze_artikel') }}
),

hauptwarengruppe as (
    select *
    from {{ ref('vms_silver_hauptwarengruppe') }}
),

nebenwarengruppe as (
    select *
    from {{ ref('vms_silver_nebenwarengruppe') }}
),

lieferant as (
    select *
    from {{ ref('vms_silver_lieferant') }}
),

tos as (
select distinct         
        ar_text as art_artikelnummer
    from {{ ref('wencke_bronze_tos_artikel_attribut') }}
    where ar_art = 1389
)

select 
    artikel.art_artikelnummer,
    artikel.art_artikelname,
    artikel.art_artikelnummer || '-' || artikel.art_artikelname as art_bezeichnung,

    hauptwarengruppe.wg_nummer as art_hauptwarengruppe_nummer,

    coalesce(hauptwarengruppe.wg_name, 'keine Bezeichnung') as art_hauptwarengruppe,

    coalesce(hauptwarengruppe.wg_nummer, 'XX') || '-' || 
    coalesce(hauptwarengruppe.wg_name, 'keine Bezeichnung') 
        as art_hauptwarenbezeichnung,

    nebenwarengruppe.wg_nummer as art_nebenwarengruppe_nummer,

    coalesce(nebenwarengruppe.wg_name, 'keine Bezeichnung') 
        as art_nebenwarengruppe,

    coalesce(nebenwarengruppe.wg_nummer, 'XX') || '-' || 
    coalesce(nebenwarengruppe.wg_name, 'keine Bezeichnung') 
        as art_nebenwarengruppebezeichnung,

    artikel.art_herstellernummer,

    coalesce(lieferant.adr_standardlieferantname, 'keine Bezeichnung') as art_lieferant,

    coalesce(cast(lieferant.art_standardlieferantnummer as varchar(30)), 'XX') || '-' || 
    coalesce(lieferant.adr_standardlieferantname, 'keine Bezeichnung') 
        as art_lieferantbezeichnung,

    case 
        when artikel.art_divers_flag = 'J' then 'Nur diverse Produkten'
        else 'Ohne diversen Produkten'
    end as art_divers_flag,

    artikel.art_ek_netto,
    artikel.art_lagereinheit,
    artikel.art_bezeichnung_2,
    artikel.art_bezeichnung_3,
    artikel.art_bezeichnung_4,
    artikel.artikel_ohne_temperaturgrenze,
    artikel.art_temperaturgrenze_vorhanden,
    artikel.art_Lagertemperatur_von,
    artikel.art_lagertemperatur_bis,
    artikel.art_transporttemperatur_von,
    artikel.art_transporttemperatur_bis

    case
        when tos.art_artikelnummer is not null then 'J'
        else 'N'
    end as art_tos_verfuegbar

from artikel

left join hauptwarengruppe 
    on artikel.art_hauptkategorie_id = hauptwarengruppe.wg_nummer

left join nebenwarengruppe 
    on artikel.art_nebenkategorie_id = nebenwarengruppe.wg_nummer

left join lieferant 
    on artikel.art_standardlieferantnummer = lieferant.art_standardlieferantnummer

left join tos
    on tos.art_artikelnummer = artikel.art_artikelnummer

order by artikel.art_artikelnummer