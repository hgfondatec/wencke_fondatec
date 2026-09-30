{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH raw_data AS (
    SELECT
        *,
        NULLIF(TRIM(idbid0201_84_10), '') AS gueltig_ab_raw,
        NULLIF(TRIM(idbid0201_94_10), '') AS gueltig_bis_raw,
        NULLIF(TRIM(idbid0201_331_10), '') AS datum_bis_gerettet_raw
    FROM {{ source('raw', 'm36stupre_dwh') }}
),

parsed AS (
    SELECT
        *,

        CASE WHEN gueltig_ab_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_ab_raw, '.', 1)::int END AS ga_tag,
        CASE WHEN gueltig_ab_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_ab_raw, '.', 2)::int END AS ga_monat,
        CASE WHEN gueltig_ab_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_ab_raw, '.', 3)::int END AS ga_jahr,

        CASE WHEN gueltig_bis_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_bis_raw, '.', 1)::int END AS gb_tag,
        CASE WHEN gueltig_bis_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_bis_raw, '.', 2)::int END AS gb_monat,
        CASE WHEN gueltig_bis_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(gueltig_bis_raw, '.', 3)::int END AS gb_jahr,

        CASE WHEN datum_bis_gerettet_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(datum_bis_gerettet_raw, '.', 1)::int END AS dg_tag,
        CASE WHEN datum_bis_gerettet_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(datum_bis_gerettet_raw, '.', 2)::int END AS dg_monat,
        CASE WHEN datum_bis_gerettet_raw ~ '^\d{2}\.\d{2}\.\d{4}$'
            THEN SPLIT_PART(datum_bis_gerettet_raw, '.', 3)::int END AS dg_jahr

    FROM raw_data
),

sortimentpreise AS (
    SELECT
        36 AS mandant,
        NULLIF(TRIM(idbid0201_50_25), '') AS artikel,
        NULLIF(TRIM(idbid0201_76_8), '') AS adr_nr,

        -- Gültig ab
        CASE
            WHEN ga_jahr >= 1900
             AND ga_monat BETWEEN 1 AND 12
             AND ga_tag BETWEEN 1 AND
                 EXTRACT(
                     DAY FROM (
                         MAKE_DATE(ga_jahr, ga_monat, 1)
                         + INTERVAL '1 month - 1 day'
                     )
                 )
            THEN MAKE_DATE(ga_jahr, ga_monat, ga_tag)
        END AS gueltig_ab,

        -- Gültig bis
        CASE
            WHEN gb_jahr >= 1900
             AND gb_monat BETWEEN 1 AND 12
             AND gb_tag BETWEEN 1 AND
                 EXTRACT(
                     DAY FROM (
                         MAKE_DATE(gb_jahr, gb_monat, 1)
                         + INTERVAL '1 month - 1 day'
                     )
                 )
            THEN MAKE_DATE(gb_jahr, gb_monat, gb_tag)
        END AS gueltig_bis,

        CAST(NULLIF(REPLACE(TRIM(idbid0201_323_8), ',', '.'), '') AS NUMERIC) AS stuetungswert,

        -- Datum bis gerettet
        CASE
            WHEN dg_jahr >= 1900
             AND dg_monat BETWEEN 1 AND 12
             AND dg_tag BETWEEN 1 AND
                 EXTRACT(
                     DAY FROM (
                         MAKE_DATE(dg_jahr, dg_monat, 1)
                         + INTERVAL '1 month - 1 day'
                     )
                 )
            THEN MAKE_DATE(dg_jahr, dg_monat, dg_tag)
        END AS datum_bis_gerettet,

        NULLIF(TRIM(idbid0201_467_1), '') AS l_sonder_ek,
        NULLIF(TRIM(idbid0201_468_1), '') AS art_stuetzung,

        CAST(NULLIF(REPLACE(TRIM(idbid0201_372_8), ',', '.'), '') AS NUMERIC) AS fap_aktuell,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_388_8), ',', '.'), '') AS NUMERIC) AS naturalrabatt,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_412_9), ',', '.'), '') AS NUMERIC) AS kew,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_421_8), ',', '.'), '') AS NUMERIC) AS sonder_ek,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_429_8), ',', '.'), '') AS NUMERIC) AS kunde_vk,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_437_6), ',', '.'), '') AS NUMERIC) AS rohertrag_marge,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_481_8), ',', '.'), '') AS NUMERIC) AS l_preis,
        CAST(NULLIF(REPLACE(TRIM(idbid0201_489_8), ',', '.'), '') AS NUMERIC) AS rabatt_plus_minus,

        NULLIF(TRIM(idbid0201_521_1), '') AS rabatt_zeichen

    FROM parsed
)

SELECT *
FROM sortimentpreise