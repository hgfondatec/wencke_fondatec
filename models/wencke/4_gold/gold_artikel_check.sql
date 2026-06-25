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
    case when t36.art_artikelnummer is not null then 1 else 0 end as verfuegbar_36

    , t39.art_artikelname as art_artikelname_39
    , t32.art_artikelname as art_artikelname_32
    , t42.art_artikelname as art_artikelname_42
    , t36.art_artikelname as art_artikelname_36

    -- , t39.art_bezeichnung as art_bezeichnung_39
    -- , t32.art_bezeichnung as art_bezeichnung_32
    -- , t42.art_bezeichnung as art_bezeichnung_42
    -- , t36.art_bezeichnung as art_bezeichnung_36

    -- , t39.art_ek_netto as art_ek_netto_39
    -- , t32.art_ek_netto as art_ek_netto_32
    -- , t42.art_ek_netto as art_ek_netto_42
    -- , t36.art_ek_netto as art_ek_netto_36


from artikel_ids base

left join t39 on base.art_artikelnummer = t39.art_artikelnummer
left join t32 on base.art_artikelnummer = t32.art_artikelnummer
left join t42 on base.art_artikelnummer = t42.art_artikelnummer
left join t36 on base.art_artikelnummer = t36.art_artikelnummer

order by base.art_artikelnummer