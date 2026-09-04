{{
    config(
        materialized='table',
        tags=['artikel']
    )
}}

with kategorien as (

    select *
    from {{ ref('silver_wencke_kategorien') }}

)

select distinct
    concat(
        mandant,
        '_',
        nebenkategorie_nummer
    ) as kategorie_key,
    mandant,
    hauptkategorie_nummer,
    hauptkategorie_name,
    nebenkategorie_nummer,
    nebenkategorie_name
from kategorien
where nebenkategorie_nummer is not null
order by
    mandant,
    hauptkategorie_nummer,
    nebenkategorie_nummer