{{
    config(
        materialized='table',
        tags=['warengruppe_check']
    )
}}

with warengruppen_ids as (

    select distinct art_hauptwarengruppe_nummer as wg_nummer
    from {{ ref('glasofix_gold_artikel') }}

    union

    select distinct art_hauptwarengruppe_nummer
    from {{ ref('lloyd_gold_artikel') }}

    union

    select distinct art_hauptwarengruppe_nummer
    from {{ ref('vms_gold_artikel') }}

    union

    select distinct art_hauptwarengruppe_nummer
    from {{ ref('nonne_gold_artikel_v2') }}

),

t39 as (

    select
        art_hauptwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from {{ ref('glasofix_gold_artikel') }}
    group by art_hauptwarengruppe_nummer

),

t32 as (

    select
        art_hauptwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from {{ ref('lloyd_gold_artikel') }}
    group by art_hauptwarengruppe_nummer

),

t42 as (

    select
        art_hauptwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from {{ ref('vms_gold_artikel') }}
    group by art_hauptwarengruppe_nummer

),

t36 as (

    select
        art_hauptwarengruppe_nummer as wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from {{ ref('nonne_gold_artikel_v2') }}
    group by art_hauptwarengruppe_nummer

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

    t39.art_hauptwarengruppe as art_hauptwarengruppe_39,
    t32.art_hauptwarengruppe as art_hauptwarengruppe_32,
    t42.art_hauptwarengruppe as art_hauptwarengruppe_42,
    t36.art_hauptwarengruppe as art_hauptwarengruppe_36,

    {{ match_score('art_hauptwarengruppe') }} as art_hauptwarengruppe_matchscore,
    {{ match_value('art_hauptwarengruppe') }} as art_hauptwarengruppe_match,

    t39.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_39,
    t32.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_32,
    t42.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_42,
    t36.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_36,

    {{ match_score('art_hauptwarenbezeichnung') }} as art_hauptwarenbezeichnung_matchscore,
    {{ match_value('art_hauptwarenbezeichnung') }} as art_hauptwarenbezeichnung_match

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