{{
    config(
        materialized = 'table',
        tags = ['artikel']
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
    hauptkategorie_harmonisiert,

    nebenkategorie_nummer,
    nebenkategorie_name,
    nebenkategorie_harmonisiert

FROM {{ ref('silver_wencke_artikel_kategorien') }}

WHERE nebenkategorie_nummer IS NOT NULL

ORDER BY
    mandant,
    hauptkategorie_nummer,
    nebenkategorie_nummer