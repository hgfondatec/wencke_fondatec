{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_lieferant AS (

    SELECT DISTINCT
        mandant,
        art_artikelnummer,
        art_herstellernummer,
        art_lieferant,
        art_lieferantbezeichnung,
        topserv_lieferanten_nr,
        adr_zentral_kunden_nr,

        NULLIF(
            TRIM(
                REGEXP_REPLACE(
                    art_lieferantbezeichnung,
                    '^\s*[0-9]+\s*-\s*',
                    ''
                )
            ),
            ''
        ) AS lieferantenbezeichnung_bereinigt,

        CONCAT(
            COALESCE(art_artikelnummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS artikel_key

    FROM {{ ref('silver_wencke_artikel_lieferant') }}

),

harmonisierung_basis AS (

    SELECT
        adr_zentral_kunden_nr,
        lieferantenbezeichnung_bereinigt

    FROM artikel_lieferant

    WHERE adr_zentral_kunden_nr IS NOT NULL
      AND lieferantenbezeichnung_bereinigt IS NOT NULL

    GROUP BY
        adr_zentral_kunden_nr,
        lieferantenbezeichnung_bereinigt

),

harmonisierung AS (

    SELECT
        adr_zentral_kunden_nr,
        lieferantenbezeichnung_bereinigt
            AS adr_zentral_kunden_name_harmonisiert

    FROM (

        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY adr_zentral_kunden_nr
                ORDER BY
                    CASE
                        WHEN LENGTH(lieferantenbezeichnung_bereinigt) >= 5 THEN 0
                        ELSE 1
                    END,
                    LENGTH(lieferantenbezeichnung_bereinigt) ASC,
                    lieferantenbezeichnung_bereinigt ASC
            ) AS rn

        FROM harmonisierung_basis

    ) x

    WHERE rn = 1

)

SELECT
    a.mandant,
    a.art_artikelnummer,
    a.art_herstellernummer,
    a.art_lieferant,
    a.art_lieferantbezeichnung,
    a.topserv_lieferanten_nr,
    a.adr_zentral_kunden_nr,
    a.artikel_key,

    h.adr_zentral_kunden_name_harmonisiert
        AS "adr_zentral_kunden_name (harmonisiert)",

    CASE
        WHEN a.adr_zentral_kunden_nr IS NOT NULL
         AND h.adr_zentral_kunden_name_harmonisiert IS NOT NULL
        THEN CONCAT(
            a.adr_zentral_kunden_nr,
            ' - ',
            h.adr_zentral_kunden_name_harmonisiert
        )

        WHEN a.adr_zentral_kunden_nr IS NOT NULL
        THEN a.adr_zentral_kunden_nr::text

        WHEN h.adr_zentral_kunden_name_harmonisiert IS NOT NULL
        THEN h.adr_zentral_kunden_name_harmonisiert

        ELSE NULL

    END AS "adr_zentral_kunden_bez (harmonisiert)"

FROM artikel_lieferant AS a

LEFT JOIN harmonisierung AS h
    ON a.adr_zentral_kunden_nr = h.adr_zentral_kunden_nr