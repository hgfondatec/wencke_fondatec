
{{ config(
    materialized = 'table',
    schema = 'tourenplanung'
) }}

WITH basis AS (
    SELECT
        *,

        -- Wirtschaftliche Bedeutung
        GREATEST(
            COALESCE(umsatz_dieses_jahr, 0),
            0
        ) AS umsatz_score_basis,

        GREATEST(
            COALESCE(rohertrag_dieses_jahr, 0),
            0
        ) AS rohertrag_score_basis,

        -- Nur negative Umsatzentwicklung erzeugt
        -- einen zusätzlichen Handlungsbedarf.
        -- Beispiel: -30 % ergibt 0.30, +20 % ergibt 0.
        CASE
            WHEN umsatz_vorjahr_ytd > 0
             AND umsatzentwicklung_prozent < 0
            THEN LEAST(
                1,
                ABS(umsatzentwicklung_prozent) / 100.0
            )
            ELSE 0
        END AS entwicklung_score_basis,

        -- Fehlende Ist-Werte nicht als 0 Besuche behandeln
        CASE
            WHEN besuchsberichte_soll > 0
             AND besuch_ist IS NOT NULL
            THEN GREATEST(
                0,
                LEAST(
                    1,
                    1 - besuch_ist::numeric
                        / besuchsberichte_soll
                )
            )
            ELSE 0.5
        END AS besuch_score_basis,

        -- Letzter Besuch: 0 bis 1 über 365 Tage
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

        ROUND((
            0.25 * score_umsatz
            + 0.25 * score_rohertrag
            + 0.25 * score_entwicklung
            + 0.10 * score_besuch
            + 0.10 * score_letzter_besuch
            + 0.05 * score_abc
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
