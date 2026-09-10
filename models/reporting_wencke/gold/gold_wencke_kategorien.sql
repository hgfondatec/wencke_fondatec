{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT DISTINCT
    CONCAT(
        mandant,
        '_',
        nebenkategorie_nummer
    ) AS kategorie_key,

    mandant,

    hauptkategorie_nummer,
    hauptkategorie_name,
    hauptkategorie_name_harmonisiert,
    hauptkategorie_bezeichnung_harmonisiert,

    nebenkategorie_nummer,
    nebenkategorie_name,
    nebenkategorie_name_harmonisiert,
    nebenkategorie_bezeichnung_harmonisiert

FROM {{ ref('silver_wencke_kategorien') }}

WHERE nebenkategorie_nummer IS NOT NULL

ORDER BY
    mandant,
    hauptkategorie_nummer,
    nebenkategorie_nummer