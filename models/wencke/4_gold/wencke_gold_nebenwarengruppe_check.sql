{{
    config(
        materialized='table',
        tags=['warengruppe_check']
    )
}}

with warengruppen_ids as (

    select distinct art_nebenwarengruppe_nummer as wg_nummer
    from {{ ref('glasofix_gold_artikel') }}

    union

    select distinct art_nebenwarengruppe_nummer
    from {{ ref('lloyd_gold_artikel') }}

    union

    select distinct art_nebenwarengruppe_nummer
    from {{ ref('vms_gold_artikel') }}

    union

    select distinct art_nebenwarengruppe_nummer
    from {{ ref('nonne_gold_artikel_v2') }}

),

t39 as (

    select
        art_nebenwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe_nummer) as art_hauptwarengruppe_nummer,
        max(art_nebenwarengruppe) as art_nebenwarengruppe,
        max(art_nebenwarengruppebezeichnung) as art_nebenwarengruppebezeichnung
    from {{ ref('glasofix_gold_artikel') }}
    group by art_nebenwarengruppe_nummer

),

t32 as (

    select
        art_nebenwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe_nummer) as art_hauptwarengruppe_nummer,
        max(art_nebenwarengruppe) as art_nebenwarengruppe,
        max(art_nebenwarengruppebezeichnung) as art_nebenwarengruppebezeichnung
    from {{ ref('lloyd_gold_artikel') }}
    group by art_nebenwarengruppe_nummer

),

t42 as (

    select
        art_nebenwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe_nummer) as art_hauptwarengruppe_nummer,
        max(art_nebenwarengruppe) as art_nebenwarengruppe,
        max(art_nebenwarengruppebezeichnung) as art_nebenwarengruppebezeichnung
    from {{ ref('vms_gold_artikel') }}
    group by art_nebenwarengruppe_nummer

),

t36 as (

    select
        art_nebenwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe_nummer) as art_hauptwarengruppe_nummer,
        max(art_nebenwarengruppe) as art_nebenwarengruppe,
        max(art_nebenwarengruppebezeichnung) as art_nebenwarengruppebezeichnung
    from {{ ref('nonne_gold_artikel_v2') }}
    group by art_nebenwarengruppe_nummer

)

select

    base.wg_nummer,

    case when t39.wg_nummer is not null then 1 else 0 end as verfuegbar_39,
    case when t32.wg_nummer is not null then 1 else 0 end as verfuegbar_32,
    case when t42.wg_nummer is not null then 1 else 0 end as verfuegbar_42,
    case when t36.wg_nummer is not null then 1 else 0 end as verfuegbar_36,

    (
        case when t39.wg_nummer is not null then 1 else 0 end +
        case when t32.wg_nummer is not null then 1 else 0 end +
        case when t42.wg_nummer is not null then 1 else 0 end +
        case when t36.wg_nummer is not null then 1 else 0 end
    ) as verfuegbar_score,

    t39.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_39,
    t32.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_32,
    t42.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_42,
    t36.art_hauptwarengruppe_nummer as art_hauptwarengruppe_nummer_36,

    {{ match_score('art_hauptwarengruppe_nummer') }} as art_hauptwarengruppe_nummer_matchscore,
    {{ match_value('art_hauptwarengruppe_nummer') }} as art_hauptwarengruppe_nummer_match,

    t39.art_nebenwarengruppe as art_nebenwarengruppe_39,
    t32.art_nebenwarengruppe as art_nebenwarengruppe_32,
    t42.art_nebenwarengruppe as art_nebenwarengruppe_42,
    t36.art_nebenwarengruppe as art_nebenwarengruppe_36,

    {{ match_score('art_nebenwarengruppe') }} as art_nebenwarengruppe_matchscore,
    {{ match_value('art_nebenwarengruppe') }} as art_nebenwarengruppe_match,

    t39.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_39,
    t32.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_32,
    t42.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_42,
    t36.art_nebenwarengruppebezeichnung as art_nebenwarengruppebezeichnung_36,

    {{ match_score('art_nebenwarengruppebezeichnung') }} as art_nebenwarengruppebezeichnung_matchscore,
    {{ match_value('art_nebenwarengruppebezeichnung') }} as art_nebenwarengruppebezeichnung_match

from warengruppen_ids base

left join t39
    on base.wg_nummer = t39.wg_nummer

left join t32
    on base.wg_nummer = t32.wg_nummer

left join t42
    on base.wg_nummer = t42.wg_nummer

left join t36
    on base.wg_nummer = t36.wg_nummer

order by base.wg_nummer