
{{ config(
    materialized = 'table',
    schema = 'tourenplanung'
) }}

WITH basis AS (
    SELECT
        *,

        -- Wirtschaftliche Bedeutung:
        -- Umsatz bleibt mit 10 % im Scoring.
        GREATEST(
            COALESCE(umsatz_dieses_jahr, 0),
            0
        ) AS umsatz_score_basis,

        -- Rohertrag bleibt als Kennzahl erhalten,
        -- wird aber nicht mehr gewichtet.
        GREATEST(
            COALESCE(rohertrag_dieses_jahr, 0),
            0
        ) AS rohertrag_score_basis,

        -- Negative Umsatzentwicklung:
        -- -30 % ergibt 0.30
        -- -100 % oder schlechter ergibt 1.00
        -- Positive Entwicklung ergibt 0.
        CASE
            WHEN umsatz_vorjahr_ytd > 0
             AND umsatzentwicklung_prozent < 0
            THEN LEAST(
                1,
                ABS(umsatzentwicklung_prozent) / 100.0
            )
            ELSE 0
        END AS entwicklung_score_basis,

        -- Besuchsdefizit:
        -- Fehlende Besuche erhöhen die Priorität.
        -- Bei unbekanntem Ist-Wert neutral 0.5.
        CASE
            WHEN COALESCE(besuchsberichte_soll, 0) <= 0
                THEN 0
            WHEN besuch_ist IS NULL
                THEN 0.5
            ELSE GREATEST(
                0,
                LEAST(
                    1,
                    1 - besuch_ist::numeric
                        / besuchsberichte_soll
                )
            )
        END AS besuch_score_basis,

        -- Letzter Besuch:
        -- Je länger der Besuch zurückliegt,
        -- desto höher die Priorität.
        -- Maximale Punktzahl nach 365 Tagen.
        CASE
            WHEN letzter_besuch IS NULL THEN 0.5
            ELSE LEAST(
                1,
                GREATEST(
                    0,
                    CURRENT_DATE - letzter_besuch
                )::numeric / 365
            )
        END AS letzter_besuch_score_basis,

        -- ABC-Klasse
        CASE UPPER(TRIM(COALESCE(adr_abc_kunde, '')))
            WHEN 'A' THEN 1.0
            WHEN 'B' THEN 0.6
            WHEN 'C' THEN 0.2
            ELSE 0.5
        END AS abc_score_basis

    FROM {{ ref('tourenplanung_kunden') }}
),

normalisierung AS (
    SELECT
        *,

        MIN(umsatz_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS min_umsatz,

        MAX(umsatz_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS max_umsatz,

        MIN(rohertrag_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS min_rohertrag,

        MAX(rohertrag_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS max_rohertrag,

        MIN(entwicklung_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS min_entwicklung,

        MAX(entwicklung_score_basis)
            OVER (PARTITION BY vertreter_key)
            AS max_entwicklung

    FROM basis
),

teil_scores AS (
    SELECT
        *,

        COALESCE(
            (umsatz_score_basis - min_umsatz)
            / NULLIF(max_umsatz - min_umsatz, 0),
            0
        ) AS score_umsatz,

        -- Bleibt zur Kompatibilität erhalten,
        -- hat aber 0 % Gewichtung.
        COALESCE(
            (rohertrag_score_basis - min_rohertrag)
            / NULLIF(max_rohertrag - min_rohertrag, 0),
            0
        ) AS score_rohertrag,

        entwicklung_score_basis AS score_entwicklung,

        besuch_score_basis AS score_besuch,

        letzter_besuch_score_basis
            AS score_letzter_besuch,

        abc_score_basis AS score_abc

    FROM normalisierung
),

ergebnis AS (
    SELECT
        *,

        -- NEUE GEWICHTUNG:
        -- Umsatz:                  10 %
        -- Rohertrag:                0 %
        -- Negative Umsatzentwicklung: 40 %
        -- Besuchsdefizit:         20 %
        -- Letzter Besuch:         20 %
        -- ABC-Klasse:             10 %
        -- Gesamt:                100 %

        ROUND((
            0.10 * score_umsatz
            + 0.40 * score_entwicklung
            + 0.20 * score_besuch
            + 0.20 * score_letzter_besuch
            + 0.10 * score_abc
        )::numeric, 4) AS score_gesamt

    FROM teil_scores
)

SELECT
    *,

    ROW_NUMBER() OVER (
        PARTITION BY vertreter_key
        ORDER BY
            score_gesamt DESC,
            beleg_adress_key
    ) AS prioritaet_rang

FROM ergebnis
