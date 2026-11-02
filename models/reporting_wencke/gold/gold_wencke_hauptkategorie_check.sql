
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['kategorie_check']
    )
}}

with kategorien as (

    select distinct
        hauptkategorie_nummer,
        mandant,
        hauptkategorie_name
    from {{ ref('silver_wencke_kategorien') }}
    where mandant in (32, 36, 39, 42)
      and hauptkategorie_nummer is not null

),

hauptkategorien_ids as (

    select distinct hauptkategorie_nummer
    from kategorien

),

t39 as (

    select
        hauptkategorie_nummer,
        max(hauptkategorie_name) as hauptkategorie_name
    from kategorien
    where mandant = 39
    group by hauptkategorie_nummer

),

t32 as (

    select
        hauptkategorie_nummer,
        max(hauptkategorie_name) as hauptkategorie_name
    from kategorien
    where mandant = 32
    group by hauptkategorie_nummer

),

t42 as (

    select
        hauptkategorie_nummer,
        max(hauptkategorie_name) as hauptkategorie_name
    from kategorien
    where mandant = 42
    group by hauptkategorie_nummer

),

t36 as (

    select
        hauptkategorie_nummer,
        max(hauptkategorie_name) as hauptkategorie_name
    from kategorien
    where mandant = 36
    group by hauptkategorie_nummer

)

select

    base.hauptkategorie_nummer,

    case when t39.hauptkategorie_nummer is not null then 1 else 0 end as verfuegbar_39,
    case when t32.hauptkategorie_nummer is not null then 1 else 0 end as verfuegbar_32,
    case when t42.hauptkategorie_nummer is not null then 1 else 0 end as verfuegbar_42,
    case when t36.hauptkategorie_nummer is not null then 1 else 0 end as verfuegbar_36,

    (
        case when t39.hauptkategorie_nummer is not null then 1 else 0 end +
        case when t32.hauptkategorie_nummer is not null then 1 else 0 end +
        case when t42.hauptkategorie_nummer is not null then 1 else 0 end +
        case when t36.hauptkategorie_nummer is not null then 1 else 0 end
    ) as verfuegbar_score,

    t39.hauptkategorie_name as hauptkategorie_name_39,
    t32.hauptkategorie_name as hauptkategorie_name_32,
    t42.hauptkategorie_name as hauptkategorie_name_42,
    t36.hauptkategorie_name as hauptkategorie_name_36,

    {{ match_score('hauptkategorie_name') }}
        as hauptkategorie_matchscore,

    {{ match_value('hauptkategorie_name') }}
        as hauptkategorie_match

from hauptkategorien_ids base

left join t39
    on base.hauptkategorie_nummer = t39.hauptkategorie_nummer

left join t32
    on base.hauptkategorie_nummer = t32.hauptkategorie_nummer

left join t42
    on base.hauptkategorie_nummer = t42.hauptkategorie_nummer

left join t36
    on base.hauptkategorie_nummer = t36.hauptkategorie_nummer

order by base.hauptkategorie_nummer
