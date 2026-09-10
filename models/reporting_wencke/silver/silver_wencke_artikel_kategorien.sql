{{
    config(
        materialized = 'table',
        tags = ['artikel']
    )
}}

WITH kategorien AS (

    SELECT
        kategorie_nr AS kategorie_nummer,
        mandant,
        wencke_id,
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

),

nebenkategorien AS (

    SELECT
        mandant,
        kategorie_nummer AS nebenkategorie_nummer,
        kategorie_name AS nebenkategorie_name,
        LEFT(kategorie_nummer, 2) AS hauptkategorie_nummer

    FROM kategorien

    WHERE is_hauptkategorie = FALSE
      AND LENGTH(kategorie_nummer) = 5

)

SELECT
    n.mandant,

    h.hauptkategorie_nummer,
    h.hauptkategorie_name,

    CONCAT(
        h.hauptkategorie_nummer,
        ' | ',
        h.hauptkategorie_name
    ) AS hauptkategorie_harmonisiert,

    n.nebenkategorie_nummer,
    n.nebenkategorie_name,

    CONCAT(
        n.nebenkategorie_nummer,
        ' | ',
        n.nebenkategorie_name
    ) AS nebenkategorie_harmonisiert

FROM nebenkategorien n

LEFT JOIN hauptkategorien h
    ON n.mandant = h.mandant
    AND n.hauptkategorie_nummer = h.hauptkategorie_nummer