
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['kategorie_check']
    )
}}

with kategorien as (

    select distinct
        nebenkategorie_nummer,
        mandant,
        nebenkategorie_name
    from {{ ref('silver_wencke_kategorien') }}
    where mandant in (32, 36, 39, 42)
      and nebenkategorie_nummer is not null

),

nebenkategorien_ids as (

    select distinct nebenkategorie_nummer
    from kategorien

),

t39 as (

    select
        nebenkategorie_nummer,
        max(nebenkategorie_name) as nebenkategorie_name
    from kategorien
    where mandant = 39
    group by nebenkategorie_nummer

),

t32 as (

    select
        nebenkategorie_nummer,
        max(nebenkategorie_name) as nebenkategorie_name
    from kategorien
    where mandant = 32
    group by nebenkategorie_nummer

),

t42 as (

    select
        nebenkategorie_nummer,
        max(nebenkategorie_name) as nebenkategorie_name
    from kategorien
    where mandant = 42
    group by nebenkategorie_nummer

),

t36 as (

    select
        nebenkategorie_nummer,
        max(nebenkategorie_name) as nebenkategorie_name
    from kategorien
    where mandant = 36
    group by nebenkategorie_nummer

)

select

    base.nebenkategorie_nummer,

    case when t39.nebenkategorie_nummer is not null then 1 else 0 end as verfuegbar_39,
    case when t32.nebenkategorie_nummer is not null then 1 else 0 end as verfuegbar_32,
    case when t42.nebenkategorie_nummer is not null then 1 else 0 end as verfuegbar_42,
    case when t36.nebenkategorie_nummer is not null then 1 else 0 end as verfuegbar_36,

    (
        case when t39.nebenkategorie_nummer is not null then 1 else 0 end +
        case when t32.nebenkategorie_nummer is not null then 1 else 0 end +
        case when t42.nebenkategorie_nummer is not null then 1 else 0 end +
        case when t36.nebenkategorie_nummer is not null then 1 else 0 end
    ) as verfuegbar_score,

    t39.nebenkategorie_name as nebenkategorie_name_39,
    t32.nebenkategorie_name as nebenkategorie_name_32,
    t42.nebenkategorie_name as nebenkategorie_name_42,
    t36.nebenkategorie_name as nebenkategorie_name_36,

    {{ match_score('nebenkategorie_name') }}
        as nebenkategorie_matchscore,

    {{ match_value('nebenkategorie_name') }}
        as nebenkategorie_match

from nebenkategorien_ids base

left join t39
    on base.nebenkategorie_nummer = t39.nebenkategorie_nummer

left join t32
    on base.nebenkategorie_nummer = t32.nebenkategorie_nummer

left join t42
    on base.nebenkategorie_nummer = t42.nebenkategorie_nummer

left join t36
    on base.nebenkategorie_nummer = t36.nebenkategorie_nummer

order by base.nebenkategorie_nummer
