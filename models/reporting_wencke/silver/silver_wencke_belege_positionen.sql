{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    --aus belege_positionen
    bp.bel_wencke_id,
    pos_nr::varchar AS pos_nr,
    pos_artikel_nr::varchar AS pos_artikel_nr,
    pos_artikel_text::varchar AS pos_artikel_text,
    pos_hersteller_nr::varchar AS pos_hersteller_nr,
    pos_steuer_spalte::varchar AS pos_steuer_spalte,
    pos_steuer_schluessel::varchar AS pos_steuer_schluessel,
    pos_steuersatz::numeric AS pos_steuersatz,
    pos_steuerberechnung::varchar AS pos_steuerberechnung,
    pos_rabattfaehig::boolean AS pos_rabattfaehig,
    pos_bonusfaehig::boolean AS pos_bonusfaehig,
    pos_skontofaehig::boolean AS pos_skontofaehig,
    pos_mengeneinheit_text::varchar AS pos_mengeneinheit_text,
    pos_umrechnungsfaktor::numeric AS pos_umrechnungsfaktor,
    pos_einzelpreis::numeric AS pos_einzelpreis,
    pos_einzelpreis2::numeric AS pos_einzelpreis2,
    pos_effektivpreis::numeric AS pos_effektivpreis,
    pos_aktionspreis::numeric AS pos_aktionspreis,
    pos_gesamtbetrag::numeric AS pos_gesamtbetrag,
    pos_gesamtbetrag_ohne_nk::numeric AS pos_gesamtbetrag_ohne_nk,
    pos_gesamtumsatz::numeric AS pos_gesamtumsatz,
    pos_ek_betrag::numeric AS pos_ek_betrag,
    pos_ek_betrag_euro::numeric AS pos_ek_betrag_euro,
    pos_rohertrag_prozent::numeric AS pos_rohertrag_prozent,
    pos_rohertrag::numeric AS pos_rohertrag,

    --aus belege_positionen_bonus
    roh_vor_bonus::numeric AS pos_rohertrag_vor_bonus,
    bonus_erledigt::boolean AS pos_bonus_erledigt,
    bonus_betrag_endgueltig::numeric AS pos_bonus_betrag_endgueltig,
    bonus_betrag_vorlaeufig::numeric AS pos_bonus_betrag_vorlaeufig,

    --aus belege_positionen
    pos_menge::numeric AS pos_menge,
    pos_skontofaehig_betrag::numeric AS pos_skontofaehig_betrag,

    'Artikelposition'::varchar AS positionsart,

    --aus belege_positionen
    pos_created_by_user::numeric AS pos_created_by_user,

    --aus belege_positionen_reklamation
    rekla_grund::varchar AS pos_rekla_grund,
    verursacher_user::numeric AS pos_verursacher_user,
    verursacher::varchar AS pos_verursacher,
    massnahme::varchar AS pos_massnahme,
    begruendung::varchar AS pos_begruendung


FROM {{ ref('bronze_wencke_belege_positionen') }} bp

LEFT JOIN {{ ref('bronze_wencke_belege_positionen_bonus') }} bpb 
    on bp.wencke_id = bpb.wencke_id

LEFT JOIN {{ ref('bronze_wencke_belege_positionen_reklamation') }} bpr
    on bp.wencke_id = bpr.wencke_id

WHERE pos_artikel_nr IS NOT NULL