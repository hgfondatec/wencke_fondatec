{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


SELECT
    wencke_lv_belege_id,

    (9000 + nk_nr)::varchar AS pos_nr,

    CASE nk_nr
        WHEN 1 THEN '09990002'
        WHEN 2 THEN '09990017'
        WHEN 3 THEN '09990013'
        WHEN 4 THEN '09990016'
        WHEN 5 THEN '09990018'
    END::varchar AS pos_artikel_nr,

    CASE nk_nr
        WHEN 1 THEN 'Fracht'
        WHEN 2 THEN 'Verpackung'
        WHEN 3 THEN 'Mindermengenzuschlag'
        WHEN 4 THEN 'Füll- und Abnutzgebühr'
        WHEN 5 THEN 'Gefahrgut'
    END::varchar AS pos_artikel_text,

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

    nk_betrag::numeric AS pos_gesamtbetrag,
    nk_betrag::numeric AS pos_gesamtbetrag_ohne_nk,

    NULL::numeric AS pos_ek_betrag,
    NULL::numeric AS pos_ek_betrag_euro,
    NULL::numeric AS pos_rohertrag_prozent,
    NULL::numeric AS pos_rohertrag,
    1::numeric AS pos_menge,
    NULL::numeric AS pos_skontofaehig_betrag,

    'Nebenkosten'::varchar AS positionsart,
    NULL::numeric AS pos_created_by_user

FROM {{ ref('bronze_wencke_belege_nebenkosten') }}

WHERE nk_betrag IS NOT NULL
  AND nk_nr IN (1, 2, 3, 4, 5)