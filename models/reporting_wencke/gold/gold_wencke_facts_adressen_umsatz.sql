
{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH basis AS (
    SELECT
        f.adress_key,
        f.artikel_key,
        f.pos_artikel_nr AS artikelnummer,
        DATE_TRUNC('month', f.bel_date)::date AS monat,

        a.adr_text,
        a.adr_abc_kunde,

        f.rechnung_umsatz_calc,
        f.rechnung_umsatz_vor_bonus_calc,
        f.rohertrag_calc,
        f.rohertrag_vor_bonus_calc,

        -- Rechnungsadresse aus Adressstamm
        CONCAT_WS(
            ', ',
            NULLIF(TRIM(a.adr_strasse), ''),
            NULLIF(
                TRIM(
                    CONCAT_WS(
                        ' ',
                        NULLIF(TRIM(a.adr_plz), ''),
                        NULLIF(TRIM(a.adr_ort), '')
                    )
                ),
                ''
            ),
            NULLIF(TRIM(a.adr_ortszusatz), '')
        ) AS rechnungsadresse,

        -- Lieferadresse aus Fact
        CASE
            WHEN NULLIF(TRIM(f.lieferant_strasse), '') IS NULL
             AND NULLIF(TRIM(f.lieferant_hausnr), '') IS NULL
             AND NULLIF(TRIM(f.lieferant_plz), '') IS NULL
             AND NULLIF(TRIM(f.lieferant_ort), '') IS NULL
            THEN 'Keine Lieferadresse hinterlegt'

            ELSE CONCAT_WS(
                ', ',
                NULLIF(
                    TRIM(
                        CONCAT_WS(
                            ' ',
                            NULLIF(TRIM(f.lieferant_strasse), ''),
                            NULLIF(TRIM(f.lieferant_hausnr), '')
                        )
                    ),
                    ''
                ),
                NULLIF(
                    TRIM(
                        CONCAT_WS(
                            ' ',
                            NULLIF(TRIM(f.lieferant_plz), ''),
                            NULLIF(TRIM(f.lieferant_ort), '')
                        )
                    ),
                    ''
                )
            )
        END AS lieferadresse

    FROM {{ ref('gold_wencke_facts_belege_positionen') }}  f

    LEFT JOIN reporting_wencke.gold_wencke_adressen a
        ON f.adress_key = a.beleg_adress_key

    WHERE
        f.umsatzrelevant IN (0, 1)

        AND (
            f.bel_beleg_bonus IS NULL
            OR f.bel_beleg_bonus = FALSE
        )

        AND f.pos_artikel_nr NOT IN ('ZZ', '09990016')
),

-- Rechnungsadresse für Kunden mit Belegen
rechnungsadressen AS (
    SELECT
        adress_key,
        artikel_key,
        artikelnummer,
        monat,
        adr_text,
        adr_abc_kunde,

        'Rechnungsadresse' AS adresstyp,
        rechnungsadresse AS adresse,

        SUM(rechnung_umsatz_calc) AS rechnung_umsatz_calc,
        SUM(rechnung_umsatz_vor_bonus_calc) AS rechnung_umsatz_vor_bonus_calc,
        SUM(rohertrag_calc) AS rohertrag_calc,
        SUM(rohertrag_vor_bonus_calc) AS rohertrag_vor_bonus_calc

    FROM basis

    GROUP BY
        adress_key,
        artikel_key,
        artikelnummer,
        monat,
        adr_text,
        adr_abc_kunde,
        rechnungsadresse
),

-- Lieferadressen für Kunden mit Belegen
lieferadressen AS (
    SELECT
        adress_key,
        artikel_key,
        artikelnummer,
        monat,
        adr_text,
        adr_abc_kunde,

        'Lieferadresse' AS adresstyp,
        lieferadresse AS adresse,

        SUM(rechnung_umsatz_calc) AS rechnung_umsatz_calc,
        SUM(rechnung_umsatz_vor_bonus_calc) AS rechnung_umsatz_vor_bonus_calc,
        SUM(rohertrag_calc) AS rohertrag_calc,
        SUM(rohertrag_vor_bonus_calc) AS rohertrag_vor_bonus_calc

    FROM basis

    GROUP BY
        adress_key,
        artikel_key,
        artikelnummer,
        monat,
        adr_text,
        adr_abc_kunde,
        lieferadresse
),

-- Monatstabelle ab 2024 bis aktueller Monat
monate AS (
    SELECT
        GENERATE_SERIES(
            DATE '2024-01-01',
            DATE_TRUNC('month', CURRENT_DATE)::date,
            INTERVAL '1 month'
        )::date AS monat
),

-- Alle Adressen, die überhaupt keine passenden Belege besitzen
adressen_ohne_belege AS (
    SELECT
        a.beleg_adress_key AS adress_key,

        NULL::text AS artikel_key,
        NULL::text AS artikelnummer,

        m.monat,

        a.adr_text,
        a.adr_abc_kunde,

        'Rechnungsadresse' AS adresstyp,

        CONCAT_WS(
            ', ',
            NULLIF(TRIM(a.adr_strasse), ''),
            NULLIF(
                TRIM(
                    CONCAT_WS(
                        ' ',
                        NULLIF(TRIM(a.adr_plz), ''),
                        NULLIF(TRIM(a.adr_ort), '')
                    )
                ),
                ''
            ),
            NULLIF(TRIM(a.adr_ortszusatz), '')
        ) AS adresse,

        0::numeric AS rechnung_umsatz_calc,
        0::numeric AS rechnung_umsatz_vor_bonus_calc,
        0::numeric AS rohertrag_calc,
        0::numeric AS rohertrag_vor_bonus_calc

    FROM reporting_wencke.gold_wencke_adressen a

    CROSS JOIN monate m

    WHERE
        a.beleg_adress_key IS NOT NULL

        AND NOT EXISTS (
            SELECT 1
            FROM reporting_wencke.gold_wencke_facts_belege_positionen f
            WHERE f.adress_key = a.beleg_adress_key
              AND f.umsatzrelevant IN (0, 1)
              AND (
                  f.bel_beleg_bonus IS NULL
                  OR f.bel_beleg_bonus = FALSE
              )
              AND f.pos_artikel_nr NOT IN ('ZZ', '09990016')
        )
)

SELECT
    adress_key,
    artikel_key,
    artikelnummer,
    monat,
    adr_text,
    adr_abc_kunde,
    adresstyp,
    adresse,
    rechnung_umsatz_calc,
    rechnung_umsatz_vor_bonus_calc,
    rohertrag_calc,
    rohertrag_vor_bonus_calc

FROM rechnungsadressen

UNION ALL

SELECT
    adress_key,
    artikel_key,
    artikelnummer,
    monat,
    adr_text,
    adr_abc_kunde,
    adresstyp,
    adresse,
    rechnung_umsatz_calc,
    rechnung_umsatz_vor_bonus_calc,
    rohertrag_calc,
    rohertrag_vor_bonus_calc

FROM lieferadressen

UNION ALL

SELECT
    adress_key,
    artikel_key,
    artikelnummer,
    monat,
    adr_text,
    adr_abc_kunde,
    adresstyp,
    adresse,
    rechnung_umsatz_calc,
    rechnung_umsatz_vor_bonus_calc,
    rohertrag_calc,
    rohertrag_vor_bonus_calc

FROM adressen_ohne_belege

ORDER BY
    adress_key,
    artikel_key,
    monat,
    adresstyp,
    adresse
