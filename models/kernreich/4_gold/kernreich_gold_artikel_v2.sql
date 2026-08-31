{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with artikel as (
    select *
    from {{ ref('kernreich_bronze_artikel') }}
),

hauptwarengruppe as (
    select *
    from {{ ref('nonne_silver_hauptwarengruppe') }}
),

nebenwarengruppe as (
    select *
    from {{ ref('nonne_silver_nebenwarengruppe') }}
),

lieferant as (
    select 

        LTRIM(adr_nr, '0') adr_nr,
        adr_text

    from {{ ref('silver_wencke_adressen') }}
    where mandant = 38
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
    artikel.art_warengruppe,
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

    lieferant.adr_nr as art_lieferant,
    coalesce(lieferant.adr_text, 'keine Bezeichnung') as art_lieferantbezeichnung,

    case 
        when artikel.art_divers_flag = 'J' then 'Nur diverse Produkten'
        else 'Ohne diversen Produkten'
    end as art_divers_flag,

    CASE
        WHEN REPLACE(REPLACE(artikel.art_ek_netto, '.', ''), ',', '.')
            ~ '^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)$'
        THEN (
            REPLACE(REPLACE(artikel.art_ek_netto, '.', ''), ',', '.')
        )::float
        ELSE NULL
    END AS art_ek_netto,
    artikel.art_lagereinheit,
    artikel.art_bezeichnung_2,
    artikel.art_bezeichnung_3,
    artikel.art_bezeichnung_4,
    artikel.art_artikel_ohne_temperaturgrenze,
    artikel.art_temperaturgrenze_vorhanden,
    artikel.art_Lagertemperatur_von,
    artikel.art_lagertemperatur_bis,
    artikel.art_transporttemperatur_von,
    artikel.art_transporttemperatur_bis,

    artikel.art_sort_kz,
    artikel.art_pauschalartikel,
    artikel.art_pflege_divisor,

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
    on TRIM(artikel.art_standardlieferantnummer) = lieferant.adr_nr

left join tos
    on tos.art_artikelnummer = artikel.art_artikelnummer

order by artikel.art_artikelnummer