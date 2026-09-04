{{
    config(
        materialized='table',
        tags=['artikel']
    )
}}

with kategorien as (

    select
        '32' as mandant,
        trim(dbk56_0_5::text) as kategorie_nummer,
        trim(dbk56_180_60::text) as kategorie_name
    from {{ source('raw', 'm32nk') }}

    union all

    select
        '36' as mandant,
        trim(dbk56_0_5::text) as kategorie_nummer,
        trim(dbk56_180_60::text) as kategorie_name
    from {{ source('raw', 'm36nk') }}

    union all

    select
        '38' as mandant,
        trim(dbk56_0_5::text) as kategorie_nummer,
        trim(dbk56_180_60::text) as kategorie_name
    from {{ source('raw', 'm38nk') }}

    union all

    select
        '39' as mandant,
        trim(dbk56_0_5::text) as kategorie_nummer,
        trim(dbk56_180_60::text) as kategorie_name
    from {{ source('raw', 'm39nk') }}

    union all

    select
        '42' as mandant,
        trim(dbk56_0_5::text) as kategorie_nummer,
        trim(dbk56_180_60::text) as kategorie_name
    from {{ source('raw', 'm42nk') }}

)

select
    mandant,
    kategorie_nummer,
    kategorie_name
from kategorien
where kategorie_nummer is not null
  and kategorie_nummer <> ''