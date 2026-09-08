{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['adressgruppe_check']
    )
}}

WITH adressgruppen AS (

    SELECT
        adrgruppe_id,
        adrgruppe_name,
        adrgruppe_mandant
    FROM {{ ref('bronze_wencke_adressen_adressgruppe') }}
    WHERE adrgruppe_mandant IN ('32', '36', '38', '39', '42')

),

adressgruppe_ids AS (

    SELECT DISTINCT
        adrgruppe_id
    FROM adressgruppen

),

t32 AS (

    SELECT *
    FROM adressgruppen
    WHERE adrgruppe_mandant = '32'

),

t36 AS (

    SELECT *
    FROM adressgruppen
    WHERE adrgruppe_mandant = '36'

),

t38 AS (

    SELECT *
    FROM adressgruppen
    WHERE adrgruppe_mandant = '38'

),

t39 AS (

    SELECT *
    FROM adressgruppen
    WHERE adrgruppe_mandant = '39'

),

t42 AS (

    SELECT *
    FROM adressgruppen
    WHERE adrgruppe_mandant = '42'

),

vergleich AS (

    SELECT
        base.adrgruppe_id,

        CASE WHEN t32.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_32,
        CASE WHEN t36.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_36,
        CASE WHEN t38.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_38,
        CASE WHEN t39.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_39,
        CASE WHEN t42.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_42,

        (
            CASE WHEN t32.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN t36.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN t38.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN t39.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN t42.adrgruppe_id IS NOT NULL THEN 1 ELSE 0 END
        ) AS verfuegbar_score,

        t32.adrgruppe_name AS adrgruppe_name_32,
        t36.adrgruppe_name AS adrgruppe_name_36,
        t38.adrgruppe_name AS adrgruppe_name_38,
        t39.adrgruppe_name AS adrgruppe_name_39,
        t42.adrgruppe_name AS adrgruppe_name_42

    FROM adressgruppe_ids base

    LEFT JOIN t32
        ON base.adrgruppe_id = t32.adrgruppe_id

    LEFT JOIN t36
        ON base.adrgruppe_id = t36.adrgruppe_id

    LEFT JOIN t38
        ON base.adrgruppe_id = t38.adrgruppe_id

    LEFT JOIN t39
        ON base.adrgruppe_id = t39.adrgruppe_id

    LEFT JOIN t42
        ON base.adrgruppe_id = t42.adrgruppe_id

),

final AS (

    SELECT
        *,

        (
            SELECT MAX(cnt)
            FROM (
                SELECT
                    value,
                    COUNT(*) AS cnt
                FROM (
                    VALUES
                        (adrgruppe_name_32),
                        (adrgruppe_name_36),
                        (adrgruppe_name_38),
                        (adrgruppe_name_39),
                        (adrgruppe_name_42)
                ) v(value)
                WHERE value IS NOT NULL
                  AND TRIM(value) <> ''
                GROUP BY value
            ) x
        ) AS adrgruppe_name_matchscore,

        (
            SELECT STRING_AGG(value, '//')
            FROM (
                SELECT DISTINCT
                    value
                FROM (
                    VALUES
                        (adrgruppe_name_32),
                        (adrgruppe_name_36),
                        (adrgruppe_name_38),
                        (adrgruppe_name_39),
                        (adrgruppe_name_42)
                ) v(value)
                WHERE value IS NOT NULL
                  AND TRIM(value) <> ''
            ) x
        ) AS adrgruppe_name_match,

        (
            SELECT value
            FROM (
                VALUES
                    (adrgruppe_name_32),
                    (adrgruppe_name_36),
                    (adrgruppe_name_38),
                    (adrgruppe_name_39),
                    (adrgruppe_name_42)
            ) v(value)
            WHERE value IS NOT NULL
              AND TRIM(value) <> ''
            GROUP BY value
            ORDER BY
                COUNT(*) DESC,
                LENGTH(REGEXP_REPLACE(value, '\s+', '', 'g')) ASC,
                value ASC
            LIMIT 1
        ) AS adrgruppe_name_reporting

    FROM vergleich

)

SELECT
    *
FROM final
ORDER BY adrgruppe_id