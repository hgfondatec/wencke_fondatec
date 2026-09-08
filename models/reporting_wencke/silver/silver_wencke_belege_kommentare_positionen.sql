{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


SELECT
    bel_wencke_id,

    NULL::varchar AS pos_nr,

    NULL::varchar AS pos_artikel_nr,

    pos_artikel_text AS pos_artikel_text,

    NULL::varchar AS pos_hersteller_nr,
    NULL::varchar AS pos_steuer_spalte,
    NULL::varchar AS pos_steuer_schluessel,
    NULL::numeric AS pos_steuersatz,
    NULL::varchar AS pos_steuerberechnung,
    NULL::boolean AS pos_rabattfaehig,
    NULL::boolean AS pos_bonusfaehig,
    NULL::boolean AS pos_skontofaehig,
    NULL::varchar AS pos_mengeneinheit_text,
    NULL::numeric AS pos_umrechnungsfaktor,
    NULL::numeric AS pos_einzelpreis,
    NULL::numeric AS pos_einzelpreis2,
    NULL::numeric AS pos_effektivpreis,
    NULL::numeric AS pos_aktionspreis,

    NULL::numeric AS pos_gesamtbetrag,
    NULL::numeric AS pos_gesamtbetrag_ohne_nk,
    NULL::numeric AS pos_gesamtumsatz,

    NULL::numeric AS pos_ek_betrag,
    NULL::numeric AS pos_ek_betrag_euro,
    NULL::numeric AS pos_rohertrag_prozent,
    NULL::numeric AS pos_rohertrag,

    --aus belege_positionen_bonus
    NULL::numeric AS pos_rohertrag_vor_bonus,
    NULL::boolean AS pos_bonus_erledigt,
    NULL::numeric AS pos_bonus_betrag_endgueltig,
    NULL::numeric AS pos_bonus_betrag_vorlaeufig,

    --aus belege_positionen
    NULL::numeric AS pos_menge,
    NULL::numeric AS pos_skontofaehig_betrag,
    NULL::numeric AS pos_gefahrgut_betrag,
    NULL::numeric AS pos_zusatzdruckspalte,
    NULL::numeric AS pos_ausgleich_akt_ek,
    NULL::numeric AS pos_stuetzung_gesamt,
    NULL::numeric AS pos_vorgabe_prozent_euro,

    'Zusatzkommentar'::varchar AS positionsart,

    --aus belege_positionen
    NULL::numeric AS pos_created_by_user,

    --aus belege_positionen_reklamation
    NULL::varchar AS pos_rekla_grund,
    NULL::numeric AS pos_verursacher_user,
    NULL::varchar AS pos_verursacher,
    NULL::varchar AS pos_massnahme,
    NULL::varchar AS pos_begruendung

FROM {{ ref('bronze_wencke_belege_positionen_kommentare') }}

WHERE kom_typ = 'Z'