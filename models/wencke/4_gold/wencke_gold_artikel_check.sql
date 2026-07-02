{{
    config(
        materialized='table',
        tags=['artikel_check']
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

),

t39 as (select * from {{ ref('glasofix_gold_artikel') }}),
t32 as (select * from {{ ref('lloyd_gold_artikel') }}),
t42 as (select * from {{ ref('vms_gold_artikel') }}),
t36 as (select * from {{ ref('nonne_gold_artikel_v2') }})

select
    base.art_artikelnummer,

    case when t39.art_artikelnummer is not null then 1 else 0 end as verfuegbar_39,
    case when t32.art_artikelnummer is not null then 1 else 0 end as verfuegbar_32,
    case when t42.art_artikelnummer is not null then 1 else 0 end as verfuegbar_42,
    case when t36.art_artikelnummer is not null then 1 else 0 end as verfuegbar_36,

    (
        case when t39.art_artikelnummer is not null then 1 else 0 end +
        case when t32.art_artikelnummer is not null then 1 else 0 end +
        case when t42.art_artikelnummer is not null then 1 else 0 end +
        case when t36.art_artikelnummer is not null then 1 else 0 end
    ) as verfuegbar_score,

    case
        when coalesce(
            t39.art_tos_verfuegbar,
            t32.art_tos_verfuegbar,
            t42.art_tos_verfuegbar,
            t36.art_tos_verfuegbar
        ) = 'J'
        then 'J'
        else 'N'
    end as art_tos_verfuegbar,

    t39.art_artikelname                                     as art_artikelname_39,
    t32.art_artikelname                                     as art_artikelname_32,
    t42.art_artikelname                                     as art_artikelname_42,
    t36.art_artikelname                                     as art_artikelname_36,
    {{ match_score('art_artikelname') }}                    as art_artikelname_matchscore,
    {{ match_value('art_artikelname') }}                    as art_artikelname_match,

    t39.art_bezeichnung                                     as art_bezeichnung_39,
    t32.art_bezeichnung                                     as art_bezeichnung_32,
    t42.art_bezeichnung                                     as art_bezeichnung_42,
    t36.art_bezeichnung                                     as art_bezeichnung_36,
    {{ match_score('art_bezeichnung') }}                    as art_bezeichnung_matchscore,
    {{ match_value('art_bezeichnung') }}                    as art_bezeichnung_match,

    t39.art_bezeichnung_2                                   as art_bezeichnung_2_39,
    t32.art_bezeichnung_2                                   as art_bezeichnung_2_32,
    t42.art_bezeichnung_2                                   as art_bezeichnung_2_42,
    t36.art_bezeichnung_2                                   as art_bezeichnung_2_36,
    {{ match_score('art_bezeichnung_2') }}                  as art_bezeichnung_2_matchscore,
    {{ match_value('art_bezeichnung_2') }}                  as art_bezeichnung_2_match,

    t39.art_bezeichnung_3                                   as art_bezeichnung_3_39,
    t32.art_bezeichnung_3                                   as art_bezeichnung_3_32,
    t42.art_bezeichnung_3                                   as art_bezeichnung_3_42,
    t36.art_bezeichnung_3                                   as art_bezeichnung_3_36,
    {{ match_score('art_bezeichnung_3') }}                  as art_bezeichnung_3_matchscore,
    {{ match_value('art_bezeichnung_3') }}                  as art_bezeichnung_3_match,

    t39.art_bezeichnung_4                                   as art_bezeichnung_4_39,
    t32.art_bezeichnung_4                                   as art_bezeichnung_4_32,
    t42.art_bezeichnung_4                                   as art_bezeichnung_4_42,
    t36.art_bezeichnung_4                                   as art_bezeichnung_4_36,
    {{ match_score('art_bezeichnung_4') }}                  as art_bezeichnung_4_matchscore,
    {{ match_value('art_bezeichnung_4') }}                  as art_bezeichnung_4_match,

    t39.art_hauptwarengruppe_nummer                         as art_hauptwarengruppe_nummer_39,
    t32.art_hauptwarengruppe_nummer                         as art_hauptwarengruppe_nummer_32,
    t42.art_hauptwarengruppe_nummer                         as art_hauptwarengruppe_nummer_42,
    t36.art_hauptwarengruppe_nummer                         as art_hauptwarengruppe_nummer_36,
    {{ match_score('art_hauptwarengruppe_nummer') }}        as art_hauptwarengruppe_nummer_matchscore,
    {{ match_value('art_hauptwarengruppe_nummer') }}        as art_hauptwarengruppe_nummer_match,

    t39.art_hauptwarengruppe                                as art_hauptwarengruppe_39,
    t32.art_hauptwarengruppe                                as art_hauptwarengruppe_32,
    t42.art_hauptwarengruppe                                as art_hauptwarengruppe_42,
    t36.art_hauptwarengruppe                                as art_hauptwarengruppe_36,
    {{ match_score('art_hauptwarengruppe') }}               as art_hauptwarengruppe_matchscore,
    {{ match_value('art_hauptwarengruppe') }}               as art_hauptwarengruppe_match,

    t39.art_hauptwarenbezeichnung                           as art_hauptwarenbezeichnung_39,
    t32.art_hauptwarenbezeichnung                           as art_hauptwarenbezeichnung_32,
    t42.art_hauptwarenbezeichnung                           as art_hauptwarenbezeichnung_42,
    t36.art_hauptwarenbezeichnung                           as art_hauptwarenbezeichnung_36,
    {{ match_score('art_hauptwarenbezeichnung') }}          as art_hauptwarenbezeichnung_matchscore,
    {{ match_value('art_hauptwarenbezeichnung') }}          as art_hauptwarenbezeichnung_match,

    t39.art_nebenwarengruppe_nummer                         as art_nebenwarengruppe_nummer_39,
    t32.art_nebenwarengruppe_nummer                         as art_nebenwarengruppe_nummer_32,
    t42.art_nebenwarengruppe_nummer                         as art_nebenwarengruppe_nummer_42,
    t36.art_nebenwarengruppe_nummer                         as art_nebenwarengruppe_nummer_36,
    {{ match_score('art_nebenwarengruppe_nummer') }}        as art_nebenwarengruppe_nummer_matchscore,
    {{ match_value('art_nebenwarengruppe_nummer') }}        as art_nebenwarengruppe_nummer_match,

    t39.art_nebenwarengruppe                                as art_nebenwarengruppe_39,
    t32.art_nebenwarengruppe                                as art_nebenwarengruppe_32,
    t42.art_nebenwarengruppe                                as art_nebenwarengruppe_42,
    t36.art_nebenwarengruppe                                as art_nebenwarengruppe_36,
    {{ match_score('art_nebenwarengruppe') }}               as art_nebenwarengruppe_matchscore,
    {{ match_value('art_nebenwarengruppe') }}               as art_nebenwarengruppe_match,

    t39.art_nebenwarengruppebezeichnung                     as art_nebenwarengruppebezeichnung_39,
    t32.art_nebenwarengruppebezeichnung                     as art_nebenwarengruppebezeichnung_32,
    t42.art_nebenwarengruppebezeichnung                     as art_nebenwarengruppebezeichnung_42,
    t36.art_nebenwarengruppebezeichnung                     as art_nebenwarengruppebezeichnung_36,
    {{ match_score('art_nebenwarengruppebezeichnung') }}    as art_nebenwarengruppebezeichnung_matchscore,
    {{ match_value('art_nebenwarengruppebezeichnung') }}    as art_nebenwarengruppebezeichnung_match,

    t39.art_herstellernummer                                as art_herstellernummer_39,
    t32.art_herstellernummer                                as art_herstellernummer_32,
    t42.art_herstellernummer                                as art_herstellernummer_42,
    t36.art_herstellernummer                                as art_herstellernummer_36,
    {{ match_score('art_herstellernummer') }}               as art_herstellernummer_matchscore,
    {{ match_value('art_herstellernummer') }}               as art_herstellernummer_match,

    t39.art_lieferant                                       as art_lieferant_39,
    t32.art_lieferant                                       as art_lieferant_32,
    t42.art_lieferant                                       as art_lieferant_42,
    t36.art_lieferant                                       as art_lieferant_36,
    {{ match_score('art_lieferant') }}                      as art_lieferant_matchscore,
    {{ match_value('art_lieferant') }}                      as art_lieferant_match,

    t39.art_lieferantbezeichnung                            as art_lieferantbezeichnung_39,
    t32.art_lieferantbezeichnung                            as art_lieferantbezeichnung_32,
    t42.art_lieferantbezeichnung                            as art_lieferantbezeichnung_42,
    t36.art_lieferantbezeichnung                            as art_lieferantbezeichnung_36,
    {{ match_score('art_lieferantbezeichnung') }}           as art_lieferantbezeichnung_matchscore,
    {{ match_value('art_lieferantbezeichnung') }}           as art_lieferantbezeichnung_match,

    t39.art_divers_flag                                     as art_divers_flag_39,
    t32.art_divers_flag                                     as art_divers_flag_32,
    t42.art_divers_flag                                     as art_divers_flag_42,
    t36.art_divers_flag                                     as art_divers_flag_36,
    {{ match_score('art_divers_flag') }}                    as art_divers_flag_matchscore,
    {{ match_value('art_divers_flag') }}                    as art_divers_flag_match,

    t39.art_ek_netto                                        as art_ek_netto_39,
    t32.art_ek_netto                                        as art_ek_netto_32,
    t42.art_ek_netto                                        as art_ek_netto_42,
    t36.art_ek_netto                                        as art_ek_netto_36,
    {{ match_score('art_ek_netto') }}                       as art_ek_netto_matchscore,
    {{ match_value('art_ek_netto') }}                       as art_ek_netto_match,

    t39.art_lagereinheit                                    as art_lagereinheit_39,
    t32.art_lagereinheit                                    as art_lagereinheit_32,
    t42.art_lagereinheit                                    as art_lagereinheit_42,
    t36.art_lagereinheit                                    as art_lagereinheit_36,
    {{ match_score('art_lagereinheit') }}                   as art_lagereinheit_matchscore,
    {{ match_value('art_lagereinheit') }}                   as art_lagereinheit_match,

    t39.art_artikel_ohne_temperaturgrenze                   as art_artikel_ohne_temperaturgrenze_39,
    t32.art_artikel_ohne_temperaturgrenze                   as art_artikel_ohne_temperaturgrenze_32,
    t42.art_artikel_ohne_temperaturgrenze                   as art_artikel_ohne_temperaturgrenze_42,
    t36.art_artikel_ohne_temperaturgrenze                   as art_artikel_ohne_temperaturgrenze_36,
    {{ match_score('art_artikel_ohne_temperaturgrenze') }}  as art_artikel_ohne_temperaturgrenze_matchscore,
    {{ match_value('art_artikel_ohne_temperaturgrenze') }}  as art_artikel_ohne_temperaturgrenze_match,

    t39.art_temperaturgrenze_vorhanden                      as art_temperaturgrenze_vorhanden_39,
    t32.art_temperaturgrenze_vorhanden                      as art_temperaturgrenze_vorhanden_32,
    t42.art_temperaturgrenze_vorhanden                      as art_temperaturgrenze_vorhanden_42,
    t36.art_temperaturgrenze_vorhanden                      as art_temperaturgrenze_vorhanden_36,
    {{ match_score('art_temperaturgrenze_vorhanden') }}     as art_temperaturgrenze_vorhanden_matchscore,
    {{ match_value('art_temperaturgrenze_vorhanden') }}     as art_temperaturgrenze_vorhanden_match,

    t39.art_lagertemperatur_von                             as art_lagertemperatur_von_39,
    t32.art_lagertemperatur_von                             as art_lagertemperatur_von_32,
    t42.art_lagertemperatur_von                             as art_lagertemperatur_von_42,
    t36.art_lagertemperatur_von                             as art_lagertemperatur_von_36,
    {{ match_score('art_lagertemperatur_von') }}            as art_lagertemperatur_von_matchscore,
    {{ match_value('art_lagertemperatur_von') }}            as art_lagertemperatur_von_match,

    t39.art_lagertemperatur_bis                             as art_lagertemperatur_bis_39,
    t32.art_lagertemperatur_bis                             as art_lagertemperatur_bis_32,
    t42.art_lagertemperatur_bis                             as art_lagertemperatur_bis_42,
    t36.art_lagertemperatur_bis                             as art_lagertemperatur_bis_36,
    {{ match_score('art_lagertemperatur_bis') }}            as art_lagertemperatur_bis_matchscore,
    {{ match_value('art_lagertemperatur_bis') }}            as art_lagertemperatur_bis_match,

    t39.art_transporttemperatur_von                         as art_transporttemperatur_von_39,
    t32.art_transporttemperatur_von                         as art_transporttemperatur_von_32,
    t42.art_transporttemperatur_von                         as art_transporttemperatur_von_42,
    t36.art_transporttemperatur_von                         as art_transporttemperatur_von_36,
    {{ match_score('art_transporttemperatur_von') }}        as art_transporttemperatur_von_matchscore,
    {{ match_value('art_transporttemperatur_von') }}        as art_transporttemperatur_von_match,

    t39.art_transporttemperatur_bis                         as art_transporttemperatur_bis_39,
    t32.art_transporttemperatur_bis                         as art_transporttemperatur_bis_32,
    t42.art_transporttemperatur_bis                         as art_transporttemperatur_bis_42,
    t36.art_transporttemperatur_bis                         as art_transporttemperatur_bis_36,
    {{ match_score('art_transporttemperatur_bis') }}        as art_transporttemperatur_bis_matchscore,
    {{ match_value('art_transporttemperatur_bis') }}        as art_transporttemperatur_bis_match

from artikel_ids base

left join t39 on base.art_artikelnummer = t39.art_artikelnummer
left join t32 on base.art_artikelnummer = t32.art_artikelnummer
left join t42 on base.art_artikelnummer = t42.art_artikelnummer
left join t36 on base.art_artikelnummer = t36.art_artikelnummer

order by base.art_artikelnummer