{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with artikel as (
    select *
    from {{ ref('bronze_artikel') }}
),

hauptwarengruppe as (
    select *
    from {{ ref('silver_hauptwarengruppe') }}
),

nebenwarengruppe as (
    select *
    from {{ ref('silver_nebenwarengruppe') }}
),

lieferant as (
    select *
    from {{ ref('silver_lieferant') }}
)

select 
    artikel.art_artikelnummer,
    artikel.art_artikelname,
    artikel.art_artikelnummer || '-' || artikel.art_artikelname as art_bezeichnung,

    coalesce(hauptwarengruppe.wg_name, 'keine Bezeichnung') as art_hauptwarengruppe,

    coalesce(hauptwarengruppe.wg_nummer, 'XX') || '-' || 
    coalesce(hauptwarengruppe.wg_name, 'keine Bezeichnung') 
        as art_hauptwarenbezeichnung,

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

    artikel.art_divers_flag


from artikel

left join hauptwarengruppe 
    on artikel.art_hauptkategorie_id = hauptwarengruppe.wg_nummer

left join nebenwarengruppe 
    on artikel.art_nebenkategorie_id = nebenwarengruppe.wg_nummer

left join lieferant 
    on artikel.art_standardlieferantnummer = lieferant.art_standardlieferantnummer

order by artikel.art_artikelnummer