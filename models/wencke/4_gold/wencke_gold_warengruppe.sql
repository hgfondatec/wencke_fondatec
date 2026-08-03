{{
    config(
        materialized='table',
        tags=['warengruppe']
    )
}}

with t39 as (

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

),

hauptwarengruppe_ids as (

    select art_hauptwarengruppe_nummer from t39
    union
    select art_hauptwarengruppe_nummer from t32
    union
    select art_hauptwarengruppe_nummer from t42
    union
    select art_hauptwarengruppe_nummer from t36
    union
    select art_hauptwarengruppe_nummer from t38

),

gold_hauptwarengruppe as (

    select

        base.art_hauptwarengruppe_nummer,

        {{ golden_value('art_hauptwarengruppe') }}
            as art_hauptwarengruppe,

        {{ golden_value('art_hauptwarenbezeichnung') }}
            as art_hauptwarenbezeichnung

    from hauptwarengruppe_ids base

    left join t39
        on base.art_hauptwarengruppe_nummer = t39.art_hauptwarengruppe_nummer

    left join t32
        on base.art_hauptwarengruppe_nummer = t32.art_hauptwarengruppe_nummer

    left join t42
        on base.art_hauptwarengruppe_nummer = t42.art_hauptwarengruppe_nummer

    left join t36
        on base.art_hauptwarengruppe_nummer = t36.art_hauptwarengruppe_nummer

    left join t38
        on base.art_hauptwarengruppe_nummer = t38.art_hauptwarengruppe_nummer

),

warengruppe_ids as (

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from t39

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from t32

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from t42

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from t36

    union

    select
        art_hauptwarengruppe_nummer,
        art_nebenwarengruppe_nummer
    from t38

)

select

    wg.art_hauptwarengruppe_nummer,
    hwg.art_hauptwarengruppe,
    hwg.art_hauptwarenbezeichnung,

    wg.art_nebenwarengruppe_nummer,

    {{ golden_value('art_nebenwarengruppe') }}
        as art_nebenwarengruppe,

    {{ golden_value('art_nebenwarengruppebezeichnung') }}
        as art_nebenwarengruppebezeichnung

from warengruppe_ids wg

left join gold_hauptwarengruppe hwg
    on wg.art_hauptwarengruppe_nummer = hwg.art_hauptwarengruppe_nummer

left join t39
    on wg.art_hauptwarengruppe_nummer = t39.art_hauptwarengruppe_nummer
   and wg.art_nebenwarengruppe_nummer = t39.art_nebenwarengruppe_nummer

left join t32
    on wg.art_hauptwarengruppe_nummer = t32.art_hauptwarengruppe_nummer
   and wg.art_nebenwarengruppe_nummer = t32.art_nebenwarengruppe_nummer

left join t42
    on wg.art_hauptwarengruppe_nummer = t42.art_hauptwarengruppe_nummer
   and wg.art_nebenwarengruppe_nummer = t42.art_nebenwarengruppe_nummer

left join t36
    on wg.art_hauptwarengruppe_nummer = t36.art_hauptwarengruppe_nummer
   and wg.art_nebenwarengruppe_nummer = t36.art_nebenwarengruppe_nummer

left join t38
    on wg.art_hauptwarengruppe_nummer = t38.art_hauptwarengruppe_nummer
   and wg.art_nebenwarengruppe_nummer = t38.art_nebenwarengruppe_nummer

group by
    wg.art_hauptwarengruppe_nummer,
    hwg.art_hauptwarengruppe,
    hwg.art_hauptwarenbezeichnung,
    wg.art_nebenwarengruppe_nummer

order by
    wg.art_hauptwarengruppe_nummer,
    wg.art_nebenwarengruppe_nummer