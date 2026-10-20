
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'nachlieferung', 'warenausgang']
    )
}}

WITH belege AS (

    SELECT
        b.mandant,
        b.wencke_id,
        DATE_TRUNC('month', b.bel_date)::date AS monat,

        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr,

        MAX(
            CASE
                WHEN b.bel_nl_nachlieferung = 'NL'
                    THEN 1
                ELSE 0
            END
        ) AS ist_nachlieferung

    FROM {{ ref('bronze_wencke_belege') }} AS b

    WHERE b.bel_art = 'L'
      AND b.bel_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '2 years'
      AND b.bel_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'

    GROUP BY
        b.mandant,
        b.wencke_id,
        DATE_TRUNC('month', b.bel_date),
        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END

)

SELECT
    mandant,
    monat,
    adr_nr,

    SUM(ist_nachlieferung) AS nl_lieferung,

    COUNT(*) AS gesamt_lieferungen,

    ROUND(
        100.0 * SUM(ist_nachlieferung)
        / NULLIF(COUNT(*), 0),
        2
    ) AS nl_quote_prozent

FROM belege

GROUP BY
    mandant,
    monat,
    adr_nr
