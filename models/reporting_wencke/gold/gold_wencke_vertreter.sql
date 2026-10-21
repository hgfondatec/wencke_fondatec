{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}
WITH vertreter AS (
    SELECT
        *,
        CONCAT(ver_vertreternummer::text, '-', ver_vertretername) AS ver_vertreternummer_name,
        CONCAT(
            COALESCE(ver_vertreternummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS vertreter_key
    FROM {{ ref('bronze_wencke_vertreter') }}
),
adressen_keys AS (
    SELECT DISTINCT
        beleg_mandant_id::text AS mandant,
        NULLIF(TRIM(vertreter_key::text), '') AS vertreter_key
    FROM {{ ref('gold_wencke_adressen') }}
    WHERE beleg_mandant_id IS NOT NULL
),
fehlende_vertreter AS (
    SELECT DISTINCT
        a.mandant,
        COALESCE(a.vertreter_key, 'Dummy_' || a.mandant) AS vertreter_key
    FROM adressen_keys a
    WHERE NOT EXISTS (
        SELECT 1
        FROM vertreter v
        WHERE v.vertreter_key = COALESCE(a.vertreter_key, 'Dummy_' || a.mandant)
    )
),
dummy_vertreter AS (
    SELECT
        f.mandant,
        NULL::text AS ver_vertreternummer,
        'Dummy'::text AS ver_vertretername,
        'Dummy'::text AS ver_vertreternummer_name,
        f.vertreter_key
    FROM fehlende_vertreter f
),
vertreter_gesamt AS (
    SELECT
        mandant::text AS mandant,
        ver_vertreternummer::text AS ver_vertreternummer,
        ver_vertretername,
        ver_vertreternummer_name,
        vertreter_key
    FROM vertreter
    UNION ALL
    SELECT
        mandant,
        ver_vertreternummer,
        ver_vertretername,
        ver_vertreternummer_name,
        vertreter_key
    FROM dummy_vertreter
    UNION ALL
    SELECT
        NULL::text AS mandant,
        NULL::text AS ver_vertreternummer,
        'Bitte Vertreter auswählen'::text AS ver_vertretername,
        'Bitte Vertreter auswählen'::text AS ver_vertreternummer_name,
        '-1'::text AS vertreter_key
)
SELECT
    mandant,
    ver_vertreternummer,
    ver_vertretername,
    ver_vertreternummer_name,
    vertreter_key
FROM vertreter_gesamt