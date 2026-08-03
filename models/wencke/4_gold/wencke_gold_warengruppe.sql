{{
    config(
        materialized='table',
        tags=['warengruppe']
    )
}}

with alle_warengruppen as (

    select distinct
        art_hauptwarengruppe_nummer,
        nullif(trim(art_hauptwarengruppe::text), '') as art_hauptwarengruppe,
        nullif(trim(art_hauptwarenbezeichnung::text), '') as art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        nullif(trim(art_nebenwarengruppe::text), '') as art_nebenwarengruppe,
        nullif(trim(art_nebenwarengruppebezeichnung::text), '') as art_nebenwarengruppebezeichnung
    from {{ ref('glasofix_gold_artikel') }}

    union all

    select distinct
        art_hauptwarengruppe_nummer,
        nullif(trim(art_hauptwarengruppe::text), ''),
        nullif(trim(art_hauptwarenbezeichnung::text), ''),
        art_nebenwarengruppe_nummer,
        nullif(trim(art_nebenwarengruppe::text), ''),
        nullif(trim(art_nebenwarengruppebezeichnung::text), '')
    from {{ ref('lloyd_gold_artikel') }}

    union all

    select distinct
        art_hauptwarengruppe_nummer,
        nullif(trim(art_hauptwarengruppe::text), ''),
        nullif(trim(art_hauptwarenbezeichnung::text), ''),
        art_nebenwarengruppe_nummer,
        nullif(trim(art_nebenwarengruppe::text), ''),
        nullif(trim(art_nebenwarengruppebezeichnung::text), '')
    from {{ ref('vms_gold_artikel') }}

    union all

    select distinct
        art_hauptwarengruppe_nummer,
        nullif(trim(art_hauptwarengruppe::text), ''),
        nullif(trim(art_hauptwarenbezeichnung::text), ''),
        art_nebenwarengruppe_nummer,
        nullif(trim(art_nebenwarengruppe::text), ''),
        nullif(trim(art_nebenwarengruppebezeichnung::text), '')
    from {{ ref('nonne_gold_artikel_v2') }}

    union all

    select distinct
        art_hauptwarengruppe_nummer,
        nullif(trim(art_hauptwarengruppe::text), ''),
        nullif(trim(art_hauptwarenbezeichnung::text), ''),
        art_nebenwarengruppe_nummer,
        nullif(trim(art_nebenwarengruppe::text), ''),
        nullif(trim(art_nebenwarengruppebezeichnung::text), '')
    from {{ ref('kernreich_gold_artikel_v2') }}

),

gold_hauptwarengruppe as (

    select distinct on (art_hauptwarengruppe_nummer)
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung

    from (
        select
            art_hauptwarengruppe_nummer,
            art_hauptwarengruppe,
            art_hauptwarenbezeichnung,
            count(*) as score

        from alle_warengruppen

        group by
            art_hauptwarengruppe_nummer,
            art_hauptwarengruppe,
            art_hauptwarenbezeichnung
    ) x

    order by
        art_hauptwarengruppe_nummer,
        score desc,
        length(regexp_replace(coalesce(art_hauptwarengruppe, ''), '\s+', '', 'g')),
        art_hauptwarengruppe

),

gold_nebenwarengruppe as (

    select distinct on (
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    )
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung

    from (
        select
            art_hauptwarengruppe_nummer,
            art_nebenwarengruppe_nummer,
            art_nebenwarengruppe,
            art_nebenwarengruppebezeichnung,
            count(*) as score

        from alle_warengruppen

        where art_nebenwarengruppe_nummer is not null

        group by
            art_hauptwarengruppe_nummer,
            art_nebenwarengruppe_nummer,
            art_nebenwarengruppe,
            art_nebenwarengruppebezeichnung
    ) x

    order by
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer,
        score desc,
        length(regexp_replace(coalesce(art_nebenwarengruppe, ''), '\s+', '', 'g')),
        art_nebenwarengruppe

)

select
    nwg.art_hauptwarengruppe_nummer,
    hwg.art_hauptwarengruppe,
    hwg.art_hauptwarenbezeichnung,
    nwg.art_nebenwarengruppe_nummer,
    nwg.art_nebenwarengruppe,
    nwg.art_nebenwarengruppebezeichnung

from gold_nebenwarengruppe nwg

left join gold_hauptwarengruppe hwg
    on nwg.art_hauptwarengruppe_nummer
       = hwg.art_hauptwarengruppe_nummer

order by
    nwg.art_hauptwarengruppe_nummer,
    nwg.art_nebenwarengruppe_nummer