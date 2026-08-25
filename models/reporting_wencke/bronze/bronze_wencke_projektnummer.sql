{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT
    idbid0136_30_8::text AS prj_lieferant,
    idbid0136_38_8::text AS prj_adr_nr,
    idbid0136_46_30::text AS prj_name,
    36 AS mandant
FROM {{ source('raw', 'm36idbid0136') }}
UNION ALL
SELECT
    idbid0136_30_8::text AS prj_lieferant,
    idbid0136_38_8::text AS prj_adr_nr,
    idbid0136_46_30::text AS prj_name,
    42 AS mandant
FROM {{ source('raw', 'm42idbid0136') }}