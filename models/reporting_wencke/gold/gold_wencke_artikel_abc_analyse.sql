
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['abc', 'bestand', 'xyz']
    )
}}

-- =========================================================
-- BESTAND JE MANDANT UND ARTIKEL
-- =========================================================

WITH bestand AS (
    SELECT
        mandant_id::text AS mandant,
        artikelnummer::text AS artikelnummer,

        MIN(
            NULLIF(TRIM(naechster_bestelltermin::text), '')::date
        ) AS naechster_bestelltermin,

        SUM(COALESCE(naechste_bestellmenge, 0)) AS naechste_bestellmenge,
        SUM(COALESCE(lagerbestand, 0)) AS lagerbestand,
        SUM(COALESCE(verfuegbar, 0)) AS verfuegbar,
        SUM(COALESCE(mindestbestand, 0)) AS mindestbestand,

        SUM(
            COALESCE(art_ek_netto, 0)
            * COALESCE(lagerbestand, 0)
        ) AS lagerwert,

        -- Frühestes vorhandenes Erfassungsdatum
        MIN(erfassungs_datum) AS erfassungs_datum

    FROM {{ ref('silver_wencke_artikel_bestand') }}

    GROUP BY
        mandant_id,
        artikelnummer
),

-- =========================================================
-- UMSATZ: LETZTE 12 MONATE INKLUSIVE HEUTE
-- =========================================================

umsatz AS (
    SELECT
        mandant::text AS mandant,
        pos_artikel_nr::text AS artikelnummer,

        SUM(
            COALESCE(rechnung_umsatz_vor_bonus_calc, 0)
        ) AS jahresumsatz,

        SUM(
            COALESCE(rechnung_menge_calc, 0)
        ) AS jahresmenge,

        SUM(
            COALESCE(rohertrag_vor_bonus_calc, 0)
        ) AS jahresrohertrag

    FROM {{ ref('gold_wencke_facts_belege_positionen') }}

    WHERE bel_date >= CURRENT_DATE - INTERVAL '12 months'
      AND bel_date < CURRENT_DATE + INTERVAL '1 day'

    GROUP BY
        mandant,
        pos_artikel_nr
),

-- =========================================================
-- 24 ROLLIERENDE MONATSFENSTER
--
-- 0-11  = aktuelle 12 Monate
-- 12-23 = vorherige 12 Monate
--
-- Der aktuelle Tag wird berücksichtigt.
-- =========================================================

rollierende_monate AS (
    SELECT
        gs.monat_index,

        (
            CURRENT_DATE
            - (gs.monat_index + 1) * INTERVAL '1 month'
        )::date AS von_datum,

        CASE
            WHEN gs.monat_index = 0
                THEN CURRENT_DATE + 1

            ELSE (
                CURRENT_DATE
                - gs.monat_index * INTERVAL '1 month'
            )::date
        END AS bis_datum_exklusiv

    FROM generate_series(0, 23) AS gs(monat_index)
),

-- =========================================================
-- ABSATZHISTORIE JE ARTIKEL UND MANDANT
-- =========================================================

historie_monat AS (
    SELECT
        f.mandant::text AS mandant,
        f.pos_artikel_nr::text AS artikelnummer,

        r.monat_index AS rollmonat_nr,

        SUM(
            COALESCE(f.rechnung_menge_calc, 0)
        ) AS monatsmenge

    FROM {{ ref('gold_wencke_facts_belege_positionen') }} f

    INNER JOIN rollierende_monate r
        ON f.bel_date >= r.von_datum
       AND f.bel_date < r.bis_datum_exklusiv

    WHERE f.bel_date >= CURRENT_DATE - INTERVAL '24 months'
      AND f.bel_date < CURRENT_DATE + INTERVAL '1 day'

    GROUP BY
        f.mandant,
        f.pos_artikel_nr,
        r.monat_index
),

-- =========================================================
-- HISTORIE JE MANDANT + GESAMT
-- =========================================================

historie_alle AS (
    SELECT
        mandant,
        artikelnummer,
        rollmonat_nr,
        monatsmenge

    FROM historie_monat

    UNION ALL

    SELECT
        'Gesamt'::text AS mandant,
        artikelnummer,
        rollmonat_nr,

        SUM(monatsmenge) AS monatsmenge

    FROM historie_monat

    GROUP BY
        artikelnummer,
        rollmonat_nr
),

-- =========================================================
-- XYZ-KENNZAHLEN UND ABSATZHISTORIE
-- =========================================================

historie_kennzahlen AS (
    SELECT
        mandant,
        artikelnummer,

        -- Anzahl aktiver Verkaufsmonate
        COUNT(*) FILTER (
            WHERE rollmonat_nr BETWEEN 0 AND 11
              AND monatsmenge > 0
        ) AS aktive_verkaufsmonate,

        -- Absatz vorherige 12 Monate
        COALESCE(
            SUM(GREATEST(monatsmenge, 0)) FILTER (
                WHERE rollmonat_nr BETWEEN 12 AND 23
            ),
            0
        ) AS menge_jahr_1,

        -- Absatz aktuelle 12 Monate
        COALESCE(
            SUM(GREATEST(monatsmenge, 0)) FILTER (
                WHERE rollmonat_nr BETWEEN 0 AND 11
            ),
            0
        ) AS menge_jahr_2

    FROM historie_alle

    GROUP BY
        mandant,
        artikelnummer
),

-- =========================================================
-- ARTIKEL JE MANDANT
-- =========================================================

artikel_mandant AS (
    SELECT
        COALESCE(b.mandant, u.mandant) AS mandant,
        COALESCE(b.artikelnummer, u.artikelnummer) AS artikelnummer,

        b.naechster_bestelltermin,

        COALESCE(b.naechste_bestellmenge, 0) AS naechste_bestellmenge,
        COALESCE(b.lagerbestand, 0) AS lagerbestand,
        COALESCE(b.verfuegbar, 0) AS verfuegbar,
        COALESCE(b.mindestbestand, 0) AS mindestbestand,
        COALESCE(b.lagerwert, 0) AS lagerwert,

        COALESCE(u.jahresumsatz, 0) AS jahresumsatz,
        COALESCE(u.jahresmenge, 0) AS jahresmenge,
        COALESCE(u.jahresrohertrag, 0) AS jahresrohertrag,

        b.erfassungs_datum

    FROM bestand b

    FULL OUTER JOIN umsatz u
        ON b.mandant = u.mandant
       AND b.artikelnummer = u.artikelnummer
),

-- =========================================================
-- GESAMT ÜBER ALLE MANDANTEN
-- =========================================================

artikel_gesamt AS (
    SELECT
        'Gesamt'::text AS mandant,
        artikelnummer,

        MIN(naechster_bestelltermin) AS naechster_bestelltermin,

        SUM(naechste_bestellmenge) AS naechste_bestellmenge,
        SUM(lagerbestand) AS lagerbestand,
        SUM(verfuegbar) AS verfuegbar,
        SUM(mindestbestand) AS mindestbestand,
        SUM(lagerwert) AS lagerwert,

        SUM(jahresumsatz) AS jahresumsatz,
        SUM(jahresmenge) AS jahresmenge,
        SUM(jahresrohertrag) AS jahresrohertrag,

        MIN(erfassungs_datum) AS erfassungs_datum

    FROM artikel_mandant

    GROUP BY
        artikelnummer
),

-- =========================================================
-- BASIS
-- =========================================================

basis AS (
    SELECT * FROM artikel_mandant

    UNION ALL

    SELECT * FROM artikel_gesamt
),

-- =========================================================
-- ABC: UMSATZRANGFOLGE
-- =========================================================

rangfolge AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY mandant
            ORDER BY jahresumsatz DESC, artikelnummer
        ) AS umsatz_rang,

        SUM(GREATEST(jahresumsatz, 0)) OVER (
            PARTITION BY mandant
        ) AS gesamtumsatz,

        SUM(GREATEST(jahresumsatz, 0)) OVER (
            PARTITION BY mandant
            ORDER BY jahresumsatz DESC, artikelnummer
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS umsatz_kumuliert

    FROM basis
),

-- =========================================================
-- ABC-KLASSIFIZIERUNG
-- =========================================================

abc AS (
    SELECT
        *,

        CASE
            WHEN jahresumsatz > 0 THEN
                ROUND(
                    (
                        jahresumsatz
                        / NULLIF(gesamtumsatz, 0) * 100
                    )::numeric,
                    2
                )
            ELSE 0
        END AS umsatzanteil_prozent,

        CASE
            WHEN jahresumsatz > 0 THEN
                ROUND(
                    (
                        umsatz_kumuliert
                        / NULLIF(gesamtumsatz, 0) * 100
                    )::numeric,
                    2
                )
            ELSE NULL
        END AS kumulierter_umsatzanteil_prozent,

        CASE
            WHEN jahresumsatz <= 0 THEN 'C'

            WHEN (
                umsatz_kumuliert - jahresumsatz
            ) / NULLIF(gesamtumsatz, 0) < 0.80
                THEN 'A'

            WHEN (
                umsatz_kumuliert - jahresumsatz
            ) / NULLIF(gesamtumsatz, 0) < 0.95
                THEN 'B'

            ELSE 'C'
        END AS abc_klasse

    FROM rangfolge
),

-- =========================================================
-- XYZ-KLASSIFIZIERUNG
-- =========================================================

klassifiziert AS (
    SELECT
        a.*,

        COALESCE(
            h.aktive_verkaufsmonate,
            0
        ) AS aktive_verkaufsmonate,

        12 AS betrachtete_monate,

        ROUND(
            (
                COALESCE(h.aktive_verkaufsmonate, 0)
                * 100.0 / 12
            )::numeric,
            2
        ) AS verkaufsfrequenz_prozent,

        CASE
            WHEN COALESCE(h.aktive_verkaufsmonate, 0) >= 10
                THEN 'X'

            WHEN COALESCE(h.aktive_verkaufsmonate, 0) >= 5
                THEN 'Y'

            ELSE 'Z'
        END AS xyz_klasse,

        COALESCE(
            h.menge_jahr_1,
            0
        ) AS absatz_historie_jahr_1,

        COALESCE(
            h.menge_jahr_2,
            0
        ) AS absatz_historie_jahr_2

    FROM abc a

    LEFT JOIN historie_kennzahlen h
        ON a.mandant = h.mandant
       AND a.artikelnummer = h.artikelnummer
)

-- =========================================================
-- FINALES ERGEBNIS
-- ABC + XYZ + BESTAND + ARTIKELALTER
-- =========================================================

SELECT
    mandant,
    artikelnummer,

    -- Erfassungsdatum und Artikelalter
    erfassungs_datum,

    (
        CURRENT_DATE - erfassungs_datum::date
    ) AS artikelalter_tage,

    -- Bestellung und Bestand
    naechster_bestelltermin,
    naechste_bestellmenge,

    lagerbestand,
    verfuegbar,
    mindestbestand,
    lagerwert,

    -- Umsatzkennzahlen
    jahresumsatz,
    jahresmenge,
    jahresrohertrag,

    -- ABC-Kennzahlen
    umsatz_rang,
    gesamtumsatz,
    umsatz_kumuliert,
    umsatzanteil_prozent,
    kumulierter_umsatzanteil_prozent,

    abc_klasse,

    CONCAT(
        abc_klasse,
        '-Artikel'
    ) AS abc_bezeichnung,

    -- XYZ-Kennzahlen
    aktive_verkaufsmonate,
    betrachtete_monate,
    verkaufsfrequenz_prozent,

    xyz_klasse,

    CASE xyz_klasse
        WHEN 'X' THEN 'X - Regelmäßig'
        WHEN 'Y' THEN 'Y - Gelegentlich'
        WHEN 'Z' THEN 'Z - Selten'
    END AS xyz_bezeichnung,

    CONCAT(
        abc_klasse,
        xyz_klasse
    ) AS abc_xyz_klasse,

    -- Absatzhistorie
    absatz_historie_jahr_1,
    absatz_historie_jahr_2

FROM klassifiziert
