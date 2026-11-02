{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['nebenkategorie_check']
    )
}}

WITH kategorien AS (

    SELECT DISTINCT
        nebenkategorie_nummer,
        hauptkategorie_nummer,
        mandant,
        nebenkategorie_name,

        CONCAT(
            nebenkategorie_nummer,
            '-',
            nebenkategorie_name
        ) AS nebenkategorie_bezeichnung

    FROM {{ ref('silver_wencke_kategorien') }}

    WHERE mandant IN (32, 36, 39, 42)
      AND nebenkategorie_nummer IS NOT NULL

),

nebenkategorien_ids AS (

    SELECT DISTINCT
        nebenkategorie_nummer
    FROM kategorien

),

t39 AS (

    SELECT
        nebenkategorie_nummer,
        MAX(hauptkategorie_nummer) AS hauptkategorie_nummer,
        MAX(nebenkategorie_name) AS nebenkategorie_name,
        MAX(nebenkategorie_bezeichnung) AS nebenkategorie_bezeichnung

    FROM kategorien
    WHERE mandant = 39
    GROUP BY nebenkategorie_nummer

),

t32 AS (

    SELECT
        nebenkategorie_nummer,
        MAX(hauptkategorie_nummer) AS hauptkategorie_nummer,
        MAX(nebenkategorie_name) AS nebenkategorie_name,
        MAX(nebenkategorie_bezeichnung) AS nebenkategorie_bezeichnung

    FROM kategorien
    WHERE mandant = 32
    GROUP BY nebenkategorie_nummer

),

t42 AS (

    SELECT
        nebenkategorie_nummer,
        MAX(hauptkategorie_nummer) AS hauptkategorie_nummer,
        MAX(nebenkategorie_name) AS nebenkategorie_name,
        MAX(nebenkategorie_bezeichnung) AS nebenkategorie_bezeichnung

    FROM kategorien
    WHERE mandant = 42
    GROUP BY nebenkategorie_nummer

),

t36 AS (

    SELECT
        nebenkategorie_nummer,
        MAX(hauptkategorie_nummer) AS hauptkategorie_nummer,
        MAX(nebenkategorie_name) AS nebenkategorie_name,
        MAX(nebenkategorie_bezeichnung) AS nebenkategorie_bezeichnung

    FROM kategorien
    WHERE mandant = 36
    GROUP BY nebenkategorie_nummer

)

SELECT

    base.nebenkategorie_nummer,

    /* VERFÜGBARKEIT */

    CASE
        WHEN t39.nebenkategorie_nummer IS NOT NULL THEN 1
        ELSE 0
    END AS verfuegbar_39,

    CASE
        WHEN t32.nebenkategorie_nummer IS NOT NULL THEN 1
        ELSE 0
    END AS verfuegbar_32,

    CASE
        WHEN t42.nebenkategorie_nummer IS NOT NULL THEN 1
        ELSE 0
    END AS verfuegbar_42,

    CASE
        WHEN t36.nebenkategorie_nummer IS NOT NULL THEN 1
        ELSE 0
    END AS verfuegbar_36,

    (
        CASE WHEN t39.nebenkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t32.nebenkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t42.nebenkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t36.nebenkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END
    ) AS verfuegbar_score,

    /* ZUGEHÖRIGE HAUPTKATEGORIE */

    t39.hauptkategorie_nummer AS hauptkategorie_nummer_39,
    t32.hauptkategorie_nummer AS hauptkategorie_nummer_32,
    t42.hauptkategorie_nummer AS hauptkategorie_nummer_42,
    t36.hauptkategorie_nummer AS hauptkategorie_nummer_36,

    {{ match_score('hauptkategorie_nummer') }}
        AS hauptkategorie_nummer_matchscore,

    {{ match_value('hauptkategorie_nummer') }}
        AS hauptkategorie_nummer_match,

    /* NEBENKATEGORIE NAME */

    t39.nebenkategorie_name AS nebenkategorie_name_39,
    t32.nebenkategorie_name AS nebenkategorie_name_32,
    t42.nebenkategorie_name AS nebenkategorie_name_42,
    t36.nebenkategorie_name AS nebenkategorie_name_36,

    {{ match_score('nebenkategorie_name') }}
        AS nebenkategorie_name_matchscore,

    {{ match_value('nebenkategorie_name') }}
        AS nebenkategorie_name_match,

    /* NEBENKATEGORIE BEZEICHNUNG */

    t39.nebenkategorie_bezeichnung AS nebenkategorie_bezeichnung_39,
    t32.nebenkategorie_bezeichnung AS nebenkategorie_bezeichnung_32,
    t42.nebenkategorie_bezeichnung AS nebenkategorie_bezeichnung_42,
    t36.nebenkategorie_bezeichnung AS nebenkategorie_bezeichnung_36,

    {{ match_score('nebenkategorie_bezeichnung') }}
        AS nebenkategorie_bezeichnung_matchscore,

    {{ match_value('nebenkategorie_bezeichnung') }}
        AS nebenkategorie_bezeichnung_match

FROM nebenkategorien_ids base

LEFT JOIN t39
    ON base.nebenkategorie_nummer = t39.nebenkategorie_nummer

LEFT JOIN t32
    ON base.nebenkategorie_nummer = t32.nebenkategorie_nummer

LEFT JOIN t42
    ON base.nebenkategorie_nummer = t42.nebenkategorie_nummer

LEFT JOIN t36
    ON base.nebenkategorie_nummer = t36.nebenkategorie_nummer

ORDER BY
    base.nebenkategorie_nummer