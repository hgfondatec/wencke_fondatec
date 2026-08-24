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
        ) AS adress_key,

        b.mandant

    FROM {{ ref('bronze_wencke_belege') }} AS b

)

SELECT
    ba_nr.adress_key AS beleg_adress_key,
    ba_nr.mandant as beleg_mandant_id,
    a.*

FROM belege_adress_nr AS ba_nr

LEFT JOIN adresse AS a
    ON ba_nr.adress_key = a.adress_key

--WHERE ba_nr.adress_key IS NOT NULL