{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH basis AS (

    SELECT *
    FROM {{ ref('bronze_wencke_adressen') }}

),

checks AS (

    SELECT
        *,

        CASE
            WHEN NULLIF(TRIM(adr_strasse), '') IS NOT NULL
            THEN TRUE
            ELSE FALSE
        END AS check_strasse_vorhanden,

        CASE
            WHEN NULLIF(TRIM(adr_strasse), '') IS NOT NULL
             AND TRIM(adr_strasse) ~ '[0-9]'
            THEN TRUE
            ELSE FALSE
        END AS check_hausnummer_vorhanden,

        CASE
            WHEN NULLIF(TRIM(adr_plz), '') IS NOT NULL
            THEN TRUE
            ELSE FALSE
        END AS check_plz_vorhanden,

        CASE
            WHEN NULLIF(TRIM(adr_ort), '') IS NOT NULL
            THEN TRUE
            ELSE FALSE
        END AS check_ort_vorhanden,

        CASE
            WHEN NULLIF(TRIM(adr_land), '') IS NULL
            THEN
                CASE
                    WHEN TRIM(COALESCE(adr_plz, '')) ~ '^[0-9]{4,5}$'
                    THEN TRUE
                    ELSE FALSE
                END

            WHEN LOWER(TRIM(adr_land)) IN (
                'de',
                'deutschland',
                'germany'
            )
            AND TRIM(COALESCE(adr_plz, '')) ~ '^[0-9]{5}$'
            THEN TRUE

            WHEN LOWER(TRIM(adr_land)) IN (
                'ch',
                'schweiz',
                'switzerland'
            )
            AND TRIM(COALESCE(adr_plz, '')) ~ '^[0-9]{4}$'
            THEN TRUE

            WHEN LOWER(TRIM(adr_land)) IN (
                'at',
                'österreich',
                'oesterreich',
                'austria'
            )
            AND TRIM(COALESCE(adr_plz, '')) ~ '^[0-9]{4}$'
            THEN TRUE

            WHEN LOWER(TRIM(adr_land)) NOT IN (
                'de',
                'deutschland',
                'germany',
                'ch',
                'schweiz',
                'switzerland',
                'at',
                'österreich',
                'oesterreich',
                'austria'
            )
            AND TRIM(COALESCE(adr_plz, '')) ~ '^[0-9]{4,6}$'
            THEN TRUE

            ELSE FALSE
        END AS check_plz_plausibel,

        CASE
            WHEN LOWER(TRIM(COALESCE(adr_strasse, ''))) IN (
                '',
                '-',
                '.',
                '0',
                'n/a',
                'na',
                'unbekannt',
                'keine angabe'
            )
            THEN FALSE
            ELSE TRUE
        END AS check_strasse_kein_platzhalter,

        CASE
            WHEN POSITION('/' IN COALESCE(adr_strasse, '')) > 0
            THEN FALSE
            ELSE TRUE
        END AS check_strasse_kein_slash,

        CASE
            WHEN LOWER(TRIM(COALESCE(adr_ort, ''))) IN (
                '',
                '-',
                '.',
                '0',
                'n/a',
                'na',
                'unbekannt',
                'keine angabe'
            )
            THEN FALSE
            ELSE TRUE
        END AS check_ort_kein_platzhalter,

        CASE
            WHEN LOWER(TRIM(COALESCE(adr_strasse, ''))) LIKE '%postfach%'
            THEN FALSE
            ELSE TRUE
        END AS check_keine_postfachadresse

    FROM basis

),

bewertung AS (

    SELECT
        *,

        CASE
            WHEN
                check_strasse_vorhanden = TRUE
                AND check_hausnummer_vorhanden = TRUE
                AND check_plz_vorhanden = TRUE
                AND check_plz_plausibel = TRUE
                AND check_ort_vorhanden = TRUE
                AND check_strasse_kein_platzhalter = TRUE
                AND check_strasse_kein_slash = TRUE
                AND check_ort_kein_platzhalter = TRUE
                AND check_keine_postfachadresse = TRUE
            THEN 'Kartentauglich'

            WHEN
                check_strasse_vorhanden = TRUE
                AND check_plz_vorhanden = TRUE
                AND check_plz_plausibel = TRUE
                AND check_ort_vorhanden = TRUE
                AND check_strasse_kein_platzhalter = TRUE
                AND check_strasse_kein_slash = TRUE
                AND check_ort_kein_platzhalter = TRUE
                AND check_keine_postfachadresse = TRUE
            THEN 'Eingeschränkt kartentauglich'

            ELSE 'Nicht kartentauglich'
        END AS adresse_karten_status,

        CONCAT_WS(
            ' | ',

            CASE
                WHEN check_strasse_vorhanden = FALSE
                THEN 'Straße fehlt'
            END,

            CASE
                WHEN check_hausnummer_vorhanden = FALSE
                 AND check_strasse_vorhanden = TRUE
                THEN 'Hausnummer fehlt'
            END,

            CASE
                WHEN check_strasse_kein_slash = FALSE
                THEN 'Straße enthält /'
            END,

            CASE
                WHEN check_plz_vorhanden = FALSE
                THEN 'PLZ fehlt'
            END,

            CASE
                WHEN check_plz_vorhanden = TRUE
                 AND check_plz_plausibel = FALSE
                THEN 'PLZ unplausibel'
            END,

            CASE
                WHEN check_ort_vorhanden = FALSE
                THEN 'Ort fehlt'
            END,

            CASE
                WHEN check_strasse_kein_platzhalter = FALSE
                THEN 'Straße enthält keinen verwertbaren Wert'
            END,

            CASE
                WHEN check_ort_kein_platzhalter = FALSE
                THEN 'Ort enthält keinen verwertbaren Wert'
            END,

            CASE
                WHEN check_keine_postfachadresse = FALSE
                THEN 'Postfachadresse'
            END

        ) AS adresse_karten_begruendung,

        CONCAT_WS(
            ', ',
            NULLIF(TRIM(adr_strasse), ''),
            CASE
                WHEN NULLIF(TRIM(adr_plz), '') IS NOT NULL
                 AND NULLIF(TRIM(adr_ort), '') IS NOT NULL
                THEN TRIM(adr_plz) || ' ' || TRIM(adr_ort)
                ELSE COALESCE(
                    NULLIF(TRIM(adr_plz), ''),
                    NULLIF(TRIM(adr_ort), '')
                )
            END,
            NULLIF(TRIM(adr_land), '')
        ) AS map_adresse

    FROM checks

)

SELECT *
FROM bewertung