{{
    config(
        materialized='table',
        tags=['artikel']
    )
}}

with artikel_ids as (

    select art_artikelnummer from {{ ref('glasofix_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('lloyd_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('vms_gold_artikel') }}
    union
    select art_artikelnummer from {{ ref('nonne_gold_artikel_v2') }}
    union
    select art_artikelnummer from {{ ref('kernreich_gold_artikel_v2') }}

),

t39 as (
    select *
    from {{ ref('glasofix_gold_artikel') }}
),

t32 as (
    select *
    from {{ ref('lloyd_gold_artikel') }}
),

t42 as (
    select *
    from {{ ref('vms_gold_artikel') }}
),

t36 as (
    select *
    from {{ ref('nonne_gold_artikel_v2') }}
),

t38 as (
    select *
    from {{ ref('kernreich_gold_artikel_v2') }}
)

select

    base.art_artikelnummer,

    {{ golden_value('art_artikelname') }} as art_artikelname,
    {{ golden_value('art_bezeichnung') }} as art_bezeichnung,
    {{ golden_value('art_bezeichnung_2') }} as art_bezeichnung_2,
    {{ golden_value('art_bezeichnung_3') }} as art_bezeichnung_3,
    {{ golden_value('art_bezeichnung_4') }} as art_bezeichnung_4,

    {{ golden_value('art_hauptwarengruppe_nummer') }} as art_hauptwarengruppe_nummer,
    {{ golden_value('art_hauptwarengruppe') }} as art_hauptwarengruppe,
    {{ golden_value('art_hauptwarenbezeichnung') }} as art_hauptwarenbezeichnung,

    {{ golden_value('art_nebenwarengruppe_nummer') }} as art_nebenwarengruppe_nummer,
    {{ golden_value('art_nebenwarengruppe') }} as art_nebenwarengruppe,
    {{ golden_value('art_nebenwarengruppebezeichnung') }} as art_nebenwarengruppebezeichnung,

    {{ golden_value('art_divers_flag') }} as art_divers_flag,
    {{ golden_value('art_ek_netto') }} as art_ek_netto,
    {{ golden_value('art_lagereinheit') }} as art_lagereinheit,

    {{ golden_value('art_artikel_ohne_temperaturgrenze') }} as art_artikel_ohne_temperaturgrenze,
    {{ golden_value('art_temperaturgrenze_vorhanden') }} as art_temperaturgrenze_vorhanden,

    {{ golden_value('art_lagertemperatur_von') }} as art_lagertemperatur_von,
    {{ golden_value('art_lagertemperatur_bis') }} as art_lagertemperatur_bis,

    {{ golden_value('art_transporttemperatur_von') }} as art_transporttemperatur_von,
    {{ golden_value('art_transporttemperatur_bis') }} as art_transporttemperatur_bis,

    {{ golden_value('art_tos_verfuegbar') }} as art_tos_verfuegbar,

    {{ golden_value('art_sort_kz') }} as art_sort_kz,
    {{ golden_value('art_pauschalartikel') }} as art_pauschalartikel,
    {{ golden_value('art_pflege_divisor') }} as art_pflege_divisor


from artikel_ids base

left join t39
    on base.art_artikelnummer = t39.art_artikelnummer

left join t32
    on base.art_artikelnummer = t32.art_artikelnummer

left join t42
    on base.art_artikelnummer = t42.art_artikelnummer

left join t36
    on base.art_artikelnummer = t36.art_artikelnummer

left join t38
    on base.art_artikelnummer = t38.art_artikelnummer

order by base.art_artikelnummer