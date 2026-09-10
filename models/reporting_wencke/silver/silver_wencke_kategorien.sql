{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH kategorien AS (

    SELECT
        kategorie_nr AS kategorie_nummer,
        mandant,
        is_hauptkategorie,
        kat_bezeichnung AS kategorie_name

    FROM {{ ref('bronze_wencke_kategorien') }}

),

hauptkategorien AS (

    SELECT
        mandant,
        kategorie_nummer AS hauptkategorie_nummer,
        kategorie_name AS hauptkategorie_name

    FROM kategorien

    WHERE is_hauptkategorie = TRUE
      AND LENGTH(kategorie_nummer) = 2

),

nebenkategorien AS (

    SELECT
        mandant,
        LEFT(kategorie_nummer, 2) AS hauptkategorie_nummer,
        kategorie_nummer AS nebenkategorie_nummer,
        kategorie_name AS nebenkategorie_name

    FROM kategorien

    WHERE is_hauptkategorie = FALSE
      AND LENGTH(kategorie_nummer) = 5

),

hauptkategorien_harmonisiert AS (

    SELECT DISTINCT ON (hauptkategorie_nummer)
        hauptkategorie_nummer,
        hauptkategorie_name AS hauptkategorie_name_harmonisiert

    FROM (
        SELECT
            hauptkategorie_nummer,
            hauptkategorie_name,
            COUNT(*) AS anzahl
        FROM hauptkategorien
        GROUP BY
            hauptkategorie_nummer,
            hauptkategorie_name
    ) x

    ORDER BY
        hauptkategorie_nummer,
        anzahl DESC,
        hauptkategorie_name

),

nebenkategorien_harmonisiert AS (

    SELECT DISTINCT ON (nebenkategorie_nummer)
        nebenkategorie_nummer,
        nebenkategorie_name AS nebenkategorie_name_harmonisiert

    FROM (
        SELECT
            nebenkategorie_nummer,
            nebenkategorie_name,
            COUNT(*) AS anzahl
        FROM nebenkategorien
        GROUP BY
            nebenkategorie_nummer,
            nebenkategorie_name
    ) x

    ORDER BY
        nebenkategorie_nummer,
        anzahl DESC,
        nebenkategorie_name

)

SELECT
    n.mandant,

    h.hauptkategorie_nummer,
    h.hauptkategorie_name,
    hh.hauptkategorie_name_harmonisiert,
    CONCAT(
        h.hauptkategorie_nummer,
        ' - ',
        hh.hauptkategorie_name_harmonisiert
    ) AS hauptkategorie_bezeichnung_harmonisiert,

    n.nebenkategorie_nummer,
    n.nebenkategorie_name,
    nh.nebenkategorie_name_harmonisiert,
    CONCAT(
        n.nebenkategorie_nummer,
        ' - ',
        nh.nebenkategorie_name_harmonisiert
    ) AS nebenkategorie_bezeichnung_harmonisiert

FROM nebenkategorien n

LEFT JOIN hauptkategorien h
    ON n.mandant = h.mandant
    AND n.hauptkategorie_nummer = h.hauptkategorie_nummer

LEFT JOIN hauptkategorien_harmonisiert hh
    ON n.hauptkategorie_nummer = hh.hauptkategorie_nummer

LEFT JOIN nebenkategorien_harmonisiert nh
    ON n.nebenkategorie_nummer = nh.nebenkategorie_nummer