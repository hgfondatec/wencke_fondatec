{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with t39 as (
    select * from {{ ref('glasofix_gold_artikel') }}
),

t32 as (
    select * from {{ ref('lloyd_gold_artikel') }}
),

t42 as (
    select * from {{ ref('vms_gold_artikel') }}
),

t36 as (
    select * from {{ ref('nonne_gold_artikel_v2') }}
),

merged as (

    select
        coalesce(
            t39.art_artikelnummer,
            t32.art_artikelnummer,
            t42.art_artikelnummer,
            t36.art_artikelnummer
        ) as art_artikelnummer,

        -- Verfügbarkeiten
        case when t39.art_artikelnummer is not null then 1 else 0 end as verfuegbar_39,
        case when t32.art_artikelnummer is not null then 1 else 0 end as verfuegbar_32,
        case when t42.art_artikelnummer is not null then 1 else 0 end as verfuegbar_42,
        case when t36.art_artikelnummer is not null then 1 else 0 end as verfuegbar_36,

        -- Beispiel-Spalten (du erweiterst das!)
        t39.art_bezeichnung as art_bezeichnung_39,
        t32.art_bezeichnung as art_bezeichnung_32,
        t42.art_bezeichnung as art_bezeichnung_42,
        t36.art_bezeichnung as art_bezeichnung_36,

        t39.art_artikelname as art_artikelname_39,
        t32.art_artikelname as art_artikelname_32,
        t42.art_artikelname as art_artikelname_42,
        t36.art_artikelname as art_artikelname_36,

        t39.art_lieferant as art_lieferant_39,
        t32.art_lieferant as art_lieferant_32,
        t42.art_lieferant as art_lieferant_42,
        t36.art_lieferant as art_lieferant_36,

        t39.art_ek_netto as art_ek_netto_39,
        t32.art_ek_netto as art_ek_netto_32,
        t42.art_ek_netto as art_ek_netto_42,
        t36.art_ek_netto as art_ek_netto_36

    from t39

    full outer join t32
        on t39.art_artikelnummer = t32.art_artikelnummer

    full outer join t42
        on coalesce(t39.art_artikelnummer, t32.art_artikelnummer) = t42.art_artikelnummer

    full outer join t36
        on coalesce(t39.art_artikelnummer, t32.art_artikelnummer, t42.art_artikelnummer) = t36.art_artikelnummer

)

select *
from merged
order by art_artikelnummer