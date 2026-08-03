{{
    config(
        materialized='table',
        tags=['warengruppe']
    )
}}

with warengruppen as (

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from {{ ref('glasofix_gold_artikel') }}

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from {{ ref('lloyd_gold_artikel') }}

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from {{ ref('vms_gold_artikel') }}

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from {{ ref('nonne_gold_artikel_v2') }}

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from {{ ref('kernreich_gold_artikel_v2') }}

),

t39 as (

    select distinct
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung
    from {{ ref('glasofix_gold_artikel') }}

),

t32 as (

    select distinct
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung
    from {{ ref('lloyd_gold_artikel') }}

),

t42 as (

    select distinct
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung
    from {{ ref('vms_gold_artikel') }}

),

t36 as (

    select distinct
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung
    from {{ ref('nonne_gold_artikel_v2') }}

),

t38 as (

    select distinct
        art_hauptwarengruppe_nummer,
        art_hauptwarengruppe,
        art_hauptwarenbezeichnung,
        art_nebenwarengruppe_nummer,
        art_nebenwarengruppe,
        art_nebenwarengruppebezeichnung
    from {{ ref('kernreich_gold_artikel_v2') }}

)

select

    base.art_hauptwarengruppe_nummer,

    {{ golden_value('art_hauptwarengruppe') }}
        as art_hauptwarengruppe,

    {{ golden_value('art_hauptwarenbezeichnung') }}
        as art_hauptwarenbezeichnung,

    base.art_nebenwarengruppe_nummer,

    {{ golden_value('art_nebenwarengruppe') }}
        as art_nebenwarengruppe,

    {{ golden_value('art_nebenwarengruppebezeichnung') }}
        as art_nebenwarengruppebezeichnung

from warengruppen base

left join t39
    on base.art_hauptwarengruppe_nummer = t39.art_hauptwarengruppe_nummer
   and base.art_nebenwarengruppe_nummer = t39.art_nebenwarengruppe_nummer

left join t32
    on base.art_hauptwarengruppe_nummer = t32.art_hauptwarengruppe_nummer
   and base.art_nebenwarengruppe_nummer = t32.art_nebenwarengruppe_nummer

left join t42
    on base.art_hauptwarengruppe_nummer = t42.art_hauptwarengruppe_nummer
   and base.art_nebenwarengruppe_nummer = t42.art_nebenwarengruppe_nummer

left join t36
    on base.art_hauptwarengruppe_nummer = t36.art_hauptwarengruppe_nummer
   and base.art_nebenwarengruppe_nummer = t36.art_nebenwarengruppe_nummer

left join t38
    on base.art_hauptwarengruppe_nummer = t38.art_hauptwarengruppe_nummer
   and base.art_nebenwarengruppe_nummer = t38.art_nebenwarengruppe_nummer