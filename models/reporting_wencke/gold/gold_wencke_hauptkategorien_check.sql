
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['warengruppe_check']
    )
}}

with kategorien as (

    select distinct
        hauptkategorie_nummer as wg_nummer,
        mandant,
        hauptkategorie_name as art_hauptwarengruppe,
        hauptkategorie_name as art_hauptwarenbezeichnung
    from {{ ref('wencke_gold_kategorien') }}
    where mandant in (32, 36, 39, 42)
      and hauptkategorie_nummer is not null

),

warengruppen_ids as (

    select distinct wg_nummer
    from kategorien

),

t39 as (

    select
        wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from kategorien
    where mandant = 39
    group by wg_nummer

),

t32 as (

    select
        wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from kategorien
    where mandant = 32
    group by wg_nummer

),

t42 as (

    select
        wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from kategorien
    where mandant = 42
    group by wg_nummer

),

t36 as (

    select
        wg_nummer,
        max(art_hauptwarengruppe) as art_hauptwarengruppe,
        max(art_hauptwarenbezeichnung) as art_hauptwarenbezeichnung
    from kategorien
    where mandant = 36
    group by wg_nummer

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

    {{ match_score('art_hauptwarengruppe') }}
        as art_hauptwarengruppe_matchscore,

    {{ match_value('art_hauptwarengruppe') }}
        as art_hauptwarengruppe_match,

    t39.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_39,
    t32.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_32,
    t42.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_42,
    t36.art_hauptwarenbezeichnung as art_hauptwarenbezeichnung_36,

    {{ match_score('art_hauptwarenbezeichnung') }}
        as art_hauptwarenbezeichnung_matchscore,

    {{ match_value('art_hauptwarenbezeichnung') }}
        as art_hauptwarenbezeichnung_match

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
