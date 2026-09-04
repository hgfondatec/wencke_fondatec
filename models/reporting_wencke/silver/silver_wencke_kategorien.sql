{{
    config(
        materialized='table',
        tags=['artikel']
    )
}}

with kategorien as (

    select *
    from {{ ref('bronze_wencke_kategorien') }}

),

hauptkategorien as (

    select
        mandant,
        kategorie_nummer as hauptkategorie_nummer,
        kategorie_name as hauptkategorie_name
    from kategorien
    where length(kategorie_nummer) = 2

),

nebenkategorien as (

    select
        mandant,
        kategorie_nummer as nebenkategorie_nummer,
        kategorie_name as nebenkategorie_name,
        left(kategorie_nummer, 2) as hauptkategorie_nummer
    from kategorien
    where length(kategorie_nummer) = 5

)

select
    n.mandant,
    h.hauptkategorie_nummer,
    h.hauptkategorie_name,
    n.nebenkategorie_nummer,
    n.nebenkategorie_name
from nebenkategorien n
left join hauptkategorien h
    on n.mandant = h.mandant
    and n.hauptkategorie_nummer = h.hauptkategorie_nummer