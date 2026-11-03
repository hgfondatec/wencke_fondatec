
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['kategorie_check']
    )
}}

WITH kategorien AS (

    SELECT DISTINCT
        hauptkategorie_nummer,
        mandant,
        hauptkategorie_name,
        CONCAT(
            hauptkategorie_nummer,
            '-',
            hauptkategorie_name
        ) AS hauptkategorie_bezeichnung

    FROM {{ ref('silver_wencke_artikel_kategorien') }}

    WHERE mandant IN (32, 36, 39, 42)
      AND hauptkategorie_nummer IS NOT NULL

),

hauptkategorien_ids AS (

    SELECT DISTINCT hauptkategorie_nummer
    FROM kategorien

),

t39 AS (

    SELECT
        hauptkategorie_nummer,
        MAX(hauptkategorie_name) AS hauptkategorie_name,
        MAX(hauptkategorie_bezeichnung) AS hauptkategorie_bezeichnung
    FROM kategorien
    WHERE mandant = 39
    GROUP BY hauptkategorie_nummer

),

t32 AS (

    SELECT
        hauptkategorie_nummer,
        MAX(hauptkategorie_name) AS hauptkategorie_name,
        MAX(hauptkategorie_bezeichnung) AS hauptkategorie_bezeichnung
    FROM kategorien
    WHERE mandant = 32
    GROUP BY hauptkategorie_nummer

),

t42 AS (

    SELECT
        hauptkategorie_nummer,
        MAX(hauptkategorie_name) AS hauptkategorie_name,
        MAX(hauptkategorie_bezeichnung) AS hauptkategorie_bezeichnung
    FROM kategorien
    WHERE mandant = 42
    GROUP BY hauptkategorie_nummer

),

t36 AS (

    SELECT
        hauptkategorie_nummer,
        MAX(hauptkategorie_name) AS hauptkategorie_name,
        MAX(hauptkategorie_bezeichnung) AS hauptkategorie_bezeichnung
    FROM kategorien
    WHERE mandant = 36
    GROUP BY hauptkategorie_nummer

)

SELECT

    base.hauptkategorie_nummer,

    /* VERFÜGBARKEIT */

    CASE WHEN t39.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_39,
    CASE WHEN t32.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_32,
    CASE WHEN t42.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_42,
    CASE WHEN t36.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_36,

    (
        CASE WHEN t39.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t32.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t42.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t36.hauptkategorie_nummer IS NOT NULL THEN 1 ELSE 0 END
    ) AS verfuegbar_score,

    /* HAUPTKATEGORIE NAME */

    t39.hauptkategorie_name AS hauptkategorie_name_39,
    t32.hauptkategorie_name AS hauptkategorie_name_32,
    t42.hauptkategorie_name AS hauptkategorie_name_42,
    t36.hauptkategorie_name AS hauptkategorie_name_36,

    {{ match_score('hauptkategorie_name') }}
        AS hauptkategorie_name_matchscore,

    {{ match_value('hauptkategorie_name') }}
        AS hauptkategorie_name_match,

    /* HAUPTKATEGORIE BEZEICHNUNG */

    t39.hauptkategorie_bezeichnung AS hauptkategorie_bezeichnung_39,
    t32.hauptkategorie_bezeichnung AS hauptkategorie_bezeichnung_32,
    t42.hauptkategorie_bezeichnung AS hauptkategorie_bezeichnung_42,
    t36.hauptkategorie_bezeichnung AS hauptkategorie_bezeichnung_36,

    {{ match_score('hauptkategorie_bezeichnung') }}
        AS hauptkategorie_bezeichnung_matchscore,

    {{ match_value('hauptkategorie_bezeichnung') }}
        AS hauptkategorie_bezeichnung_match

FROM hauptkategorien_ids base

LEFT JOIN t39
    ON base.hauptkategorie_nummer = t39.hauptkategorie_nummer

LEFT JOIN t32
    ON base.hauptkategorie_nummer = t32.hauptkategorie_nummer

LEFT JOIN t42
    ON base.hauptkategorie_nummer = t42.hauptkategorie_nummer

LEFT JOIN t36
    ON base.hauptkategorie_nummer = t36.hauptkategorie_nummer

ORDER BY base.hauptkategorie_nummer
