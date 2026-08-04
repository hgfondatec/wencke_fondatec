{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    bel_wencke_id,
    pos_nr,
    pos_artikel_nr,
    pos_artikel_text,
    pos_hersteller_nr,
    pos_steuer_spalte,
    pos_steuer_schluessel,
    pos_steuersatz,
    pos_steuerberechnung,
    pos_rabattfaehig,
    pos_bonusfaehig,
    pos_skontofaehig,
    pos_mengeneinheit_text,
    pos_umrechnungsfaktor,
    pos_einzelpreis,
    pos_einzelpreis2,
    pos_effektivpreis,
    pos_aktionspreis,
    pos_gesamtbetrag,
    pos_gesamtbetrag_ohne_nk,
    pos_gesamtumsatz,
    pos_ek_betrag,
    pos_ek_betrag_euro,
    pos_rohertrag_prozent,
    pos_rohertrag,
    pos_menge,
    pos_skontofaehig_betrag,
    pos_created_by_user
FROM {{ source('raw', 'wencke_lv_belege_positionen') }}