{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH adresse AS (

    SELECT
        a.*,

        CONCAT(
            a.adr_vertreter_nr,
            '_',
            a.mandant
        ) AS vertreter_key,

        CONCAT(
            LTRIM(a.adr_nr, '0'),
            '_',
            a.mandant
        ) AS adress_key,

        CONCAT(
            a.adr_adressgruppe,
            '_',
            a.mandant
        ) AS adr_adressgruppe_key

    FROM {{ ref('silver_wencke_adressen') }} AS a

),

belege_adress_nr AS (

    SELECT DISTINCT
        CONCAT(
            LTRIM(
                CASE
                    WHEN b.bel_project_nr IS NOT NULL
                        THEN b.bel_oe_5
                    ELSE b.bel_adr_nr
                END,
                '0'
            ),
            '_',
            b.mandant
        ) AS beleg_adress_key,

        b.mandant

    FROM {{ ref('bronze_wencke_belege') }} AS b

),

/* 1. Bestehende Beleg-/Adresslogik bleibt exakt führend */
beleg_adressen AS (

    SELECT
        ba_nr.beleg_adress_key,
        ba_nr.mandant AS beleg_mandant_id,
        a.*,
        adr.adr_adressgruppe_name

    FROM belege_adress_nr AS ba_nr

    LEFT JOIN adresse AS a
        ON ba_nr.beleg_adress_key = a.adress_key

    LEFT JOIN {{ ref('gold_wencke_adressgruppe') }} AS adr
        ON a.adr_adressgruppe_key = adr.adr_adressgruppe_key

),

/* 2. Adressen ergänzen, die in der Belegmenge noch fehlen */
fehlende_adressen AS (

    SELECT
        a.adress_key AS beleg_adress_key,
        a.mandant AS beleg_mandant_id,
        a.*,
        adr.adr_adressgruppe_name

    FROM adresse AS a

    LEFT JOIN {{ ref('gold_wencke_adressgruppe') }} AS adr
        ON a.adr_adressgruppe_key = adr.adr_adressgruppe_key

    WHERE a.adr_adressgruppe NOT IN ('10', '11', '12', '13')
        AND a.adr_vertreter_nr IS NOT NULL
        AND a.adr_gesperrt_neue_belege IS NOT TRUE

      AND NOT EXISTS (

          SELECT 1

          FROM beleg_adressen AS b

          WHERE b.adress_key = a.adress_key

      )

)

SELECT *
FROM beleg_adressen

UNION ALL

SELECT *
FROM fehlende_adressen