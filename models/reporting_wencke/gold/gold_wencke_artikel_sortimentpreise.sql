{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH sortimentpreise AS (

    SELECT
        *
    FROM {{ ref('bronze_wencke_artikel_sortimentpreise') }}

),

basis AS (

    SELECT
        *,

        -- Ist dieser Preis heute gültig?
        CASE
            WHEN CURRENT_DATE BETWEEN gueltig_ab AND gueltig_bis
                THEN TRUE
            ELSE FALSE
        END AS ist_heute_gueltig,

        -- Ist dieser Preis bereits abgelaufen?
        CASE
            WHEN gueltig_bis < CURRENT_DATE
                THEN TRUE
            ELSE FALSE
        END AS ist_abgelaufen,

        -- Liegt dieser Preis vollständig in der Zukunft?
        CASE
            WHEN gueltig_ab > CURRENT_DATE
                THEN TRUE
            ELSE FALSE
        END AS ist_zukuenftig,

        /*
        Neuester Datensatz insgesamt.

        WICHTIG:
        Mandant gehört zur Partition,
        damit gleiche Adress-/Artikelnummern verschiedener
        Mandanten nicht vermischt werden.
        */
        ROW_NUMBER() OVER (
            PARTITION BY
                mandant,
                adr_nr,
                artikel
            ORDER BY
                gueltig_bis DESC,
                gueltig_ab DESC
        ) AS aktuell_rang

    FROM sortimentpreise

),

markiert AS (

    SELECT
        *,

        /*
        Reporting-Logik:

        1. Aktuell gültiger Preis
        2. Falls keiner aktuell gültig:
           letzter bereits gestarteter Preis
        3. Zukünftige Preise werden nicht bevorzugt,
           solange ein aktueller/vergangener Preis existiert
        */
        ROW_NUMBER() OVER (
            PARTITION BY
                mandant,
                adr_nr,
                artikel
            ORDER BY

                -- höchste Priorität: heute gültig
                CASE
                    WHEN ist_heute_gueltig THEN 1
                    ELSE 0
                END DESC,

                -- danach aktuelle/vergangene Datensätze
                CASE
                    WHEN gueltig_ab <= CURRENT_DATE THEN 1
                    ELSE 0
                END DESC,

                -- davon den zeitlich neuesten
                gueltig_bis DESC,
                gueltig_ab DESC

        ) AS reporting_rang

    FROM basis

)

SELECT
    *,

    -- Neuester Datensatz insgesamt
    aktuell_rang = 1 AS ist_aktuell,

    -- Für das heutige Reporting relevanter Preis
    reporting_rang = 1 AS wird_reported,

    CONCAT(
        COALESCE(artikel::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS artikel_key,

    CONCAT(
        COALESCE(adr_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS adress_key

FROM markiert