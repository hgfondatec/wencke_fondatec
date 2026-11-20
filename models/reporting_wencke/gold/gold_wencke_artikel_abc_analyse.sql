
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['abc', 'bestand', 'xyz', 'saisonalitaet']
    )
}}

WITH bestand AS (
    SELECT
        mandant_id::text AS mandant,
        artikelnummer::text AS artikelnummer,
        MIN(NULLIF(TRIM(naechster_bestelltermin::text), '')::date) AS naechster_bestelltermin,
        SUM(COALESCE(naechste_bestellmenge, 0)) AS naechste_bestellmenge,
        SUM(COALESCE(lagerbestand, 0)) AS lagerbestand,
        SUM(COALESCE(verfuegbar, 0)) AS verfuegbar,
        SUM(COALESCE(mindestbestand, 0)) AS mindestbestand,
        SUM(COALESCE(art_ek_netto, 0) * COALESCE(lagerbestand, 0)) AS lagerwert
    FROM {{ ref('silver_wencke_artikel_bestand') }}
    GROUP BY mandant_id, artikelnummer
),
umsatz AS (
    SELECT
        mandant::text AS mandant,
        pos_artikel_nr::text AS artikelnummer,
        SUM(COALESCE(rechnung_umsatz_vor_bonus_calc, 0)) AS jahresumsatz,
        SUM(COALESCE(rechnung_menge_calc, 0)) AS jahresmenge,
        SUM(COALESCE(rohertrag_vor_bonus_calc, 0)) AS jahresrohertrag
    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE)
      AND bel_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY mandant, pos_artikel_nr
),
historie_monat AS (
    SELECT
        mandant::text AS mandant,
        pos_artikel_nr::text AS artikelnummer,
        DATE_TRUNC('month', bel_date)::date AS monat,
        SUM(COALESCE(rechnung_menge_calc, 0)) AS monatsmenge
    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    WHERE bel_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '24 months'
      AND bel_date < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY mandant, pos_artikel_nr, DATE_TRUNC('month', bel_date)::date
),
historie_alle AS (
    SELECT mandant, artikelnummer, monat, monatsmenge FROM historie_monat
    UNION ALL
    SELECT 'Gesamt'::text, artikelnummer, monat, SUM(monatsmenge)
    FROM historie_monat
    GROUP BY artikelnummer, monat
),
historie_kennzahlen AS (
    SELECT
        mandant,
        artikelnummer,
        COUNT(*) FILTER (
            WHERE monat >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
              AND monatsmenge > 0
        ) AS aktive_verkaufsmonate,
        COALESCE(SUM(GREATEST(monatsmenge, 0)) FILTER (
            WHERE monat < DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
        ), 0) AS menge_jahr_1,
        COALESCE(SUM(GREATEST(monatsmenge, 0)) FILTER (
            WHERE monat >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
        ), 0) AS menge_jahr_2
    FROM historie_alle
    GROUP BY mandant, artikelnummer
),
saisonfenster AS (
    SELECT
        h.mandant,
        h.artikelnummer,
        m.startmonat,
        COALESCE(SUM(GREATEST(h.monatsmenge, 0)) FILTER (
            WHERE h.monat < DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
              AND ((EXTRACT(MONTH FROM h.monat)::int - m.startmonat + 12) % 12) < 3
        ), 0) AS saison_menge_jahr_1,
        COALESCE(SUM(GREATEST(h.monatsmenge, 0)) FILTER (
            WHERE h.monat >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 months'
              AND ((EXTRACT(MONTH FROM h.monat)::int - m.startmonat + 12) % 12) < 3
        ), 0) AS saison_menge_jahr_2
    FROM historie_alle h
    CROSS JOIN generate_series(1, 12) AS m(startmonat)
    GROUP BY h.mandant, h.artikelnummer, m.startmonat
),
saison_auswahl AS (
    SELECT DISTINCT ON (s.mandant, s.artikelnummer)
        s.mandant,
        s.artikelnummer,
        s.startmonat,
        ((s.startmonat + 1) % 12) + 1 AS endmonat,
        ROUND((s.saison_menge_jahr_1 * 100.0 / NULLIF(k.menge_jahr_1, 0))::numeric, 2) AS saisonanteil_jahr_1_prozent,
        ROUND((s.saison_menge_jahr_2 * 100.0 / NULLIF(k.menge_jahr_2, 0))::numeric, 2) AS saisonanteil_jahr_2_prozent
    FROM saisonfenster s
    INNER JOIN historie_kennzahlen k
        ON s.mandant = k.mandant
       AND s.artikelnummer = k.artikelnummer
    WHERE k.menge_jahr_1 >= 5
      AND k.menge_jahr_2 >= 5
      AND s.saison_menge_jahr_1 >= k.menge_jahr_1 * 0.60
      AND s.saison_menge_jahr_2 >= k.menge_jahr_2 * 0.60
    ORDER BY
        s.mandant,
        s.artikelnummer,
        LEAST(
            s.saison_menge_jahr_1 * 1.0 / NULLIF(k.menge_jahr_1, 0),
            s.saison_menge_jahr_2 * 1.0 / NULLIF(k.menge_jahr_2, 0)
        ) DESC,
        s.startmonat
),
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
        COALESCE(u.jahresrohertrag, 0) AS jahresrohertrag
    FROM bestand b
    FULL OUTER JOIN umsatz u
        ON b.mandant = u.mandant
       AND b.artikelnummer = u.artikelnummer
),
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
        SUM(jahresrohertrag) AS jahresrohertrag
    FROM artikel_mandant
    GROUP BY artikelnummer
),
basis AS (
    SELECT * FROM artikel_mandant
    UNION ALL
    SELECT * FROM artikel_gesamt
),
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
abc AS (
    SELECT
        *,
        CASE
            WHEN jahresumsatz > 0 THEN ROUND((jahresumsatz / NULLIF(gesamtumsatz, 0) * 100)::numeric, 2)
            ELSE 0
        END AS umsatzanteil_prozent,
        CASE
            WHEN jahresumsatz > 0 THEN ROUND((umsatz_kumuliert / NULLIF(gesamtumsatz, 0) * 100)::numeric, 2)
            ELSE NULL
        END AS kumulierter_umsatzanteil_prozent,
        CASE
            WHEN jahresumsatz <= 0 THEN 'C'
            WHEN (umsatz_kumuliert - jahresumsatz) / NULLIF(gesamtumsatz, 0) < 0.80 THEN 'A'
            WHEN (umsatz_kumuliert - jahresumsatz) / NULLIF(gesamtumsatz, 0) < 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_klasse
    FROM rangfolge
),
klassifiziert AS (
    SELECT
        a.*,
        COALESCE(h.aktive_verkaufsmonate, 0) AS aktive_verkaufsmonate,
        12 AS betrachtete_monate,
        ROUND((COALESCE(h.aktive_verkaufsmonate, 0) * 100.0 / 12)::numeric, 2) AS verkaufsfrequenz_prozent,
        CASE
            WHEN COALESCE(h.aktive_verkaufsmonate, 0) >= 10 THEN 'X'
            WHEN COALESCE(h.aktive_verkaufsmonate, 0) >= 5 THEN 'Y'
            ELSE 'Z'
        END AS xyz_klasse,
        COALESCE(h.menge_jahr_1, 0) AS absatz_historie_jahr_1,
        COALESCE(h.menge_jahr_2, 0) AS absatz_historie_jahr_2,
        s.startmonat AS saison_startmonat,
        s.endmonat AS saison_endmonat,
        s.saisonanteil_jahr_1_prozent,
        s.saisonanteil_jahr_2_prozent,
        CASE
            WHEN COALESCE(h.menge_jahr_1, 0) < 5
              OR COALESCE(h.menge_jahr_2, 0) < 5 THEN 'U'
            WHEN s.startmonat IS NOT NULL THEN 'S'
            ELSE 'N'
        END AS saison_klasse
    FROM abc a
    LEFT JOIN historie_kennzahlen h
        ON a.mandant = h.mandant
       AND a.artikelnummer = h.artikelnummer
    LEFT JOIN saison_auswahl s
        ON a.mandant = s.mandant
       AND a.artikelnummer = s.artikelnummer
)
SELECT
    mandant,
    artikelnummer,
    naechster_bestelltermin,
    naechste_bestellmenge,
    lagerbestand,
    verfuegbar,
    mindestbestand,
    lagerwert,
    jahresumsatz,
    jahresmenge,
    jahresrohertrag,
    umsatz_rang,
    gesamtumsatz,
    umsatz_kumuliert,
    umsatzanteil_prozent,
    kumulierter_umsatzanteil_prozent,
    abc_klasse,
    CONCAT(abc_klasse, '-Artikel') AS abc_bezeichnung,
    aktive_verkaufsmonate,
    betrachtete_monate,
    verkaufsfrequenz_prozent,
    xyz_klasse,
    CASE xyz_klasse
        WHEN 'X' THEN 'X - Regelmäßig'
        WHEN 'Y' THEN 'Y - Gelegentlich'
        WHEN 'Z' THEN 'Z - Selten'
    END AS xyz_bezeichnung,
    CONCAT(abc_klasse, xyz_klasse) AS abc_xyz_klasse,
    saison_klasse,
    CASE saison_klasse
        WHEN 'S' THEN 'S - Saisonal'
        WHEN 'N' THEN 'N - Nicht saisonal'
        WHEN 'U' THEN 'U - Nicht bewertbar'
    END AS saison_bezeichnung,
    saison_startmonat,
    saison_endmonat,
    saisonanteil_jahr_1_prozent,
    saisonanteil_jahr_2_prozent,
    absatz_historie_jahr_1,
    absatz_historie_jahr_2
FROM klassifiziert
