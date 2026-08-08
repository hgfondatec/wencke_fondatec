{{ config(
    materialized = 'view',
    alias = 'easymap_customer'
) }}

WITH adressen AS (

    SELECT
        nga.adr_nr final_adress_nummer,
        nga.adr_text final_name,
        nga.adr_strasse adr_adresse,
        nga.adr_plz,
        nga.adr_ort adr_stadt,
        '' adrgruppe_name,
        nga.adr_vertreter_nr adr_vertreternummer,

        nga.adr_nr::bigint as adressnummer_num
    

    FROM {{ ref('gold_wencke_adressen') }} AS nga

    where mandant = 36

),

kunden AS (

    SELECT DISTINCT
        a.final_adress_nummer,
        a.final_name,
        a.adr_adresse,
        a.adr_plz,
        a.adr_stadt,
        a.adrgruppe_name,
        rv.ver_vertreternummer,
        rv.ver_vertretername,

        CASE
            WHEN a.adressnummer_num BETWEEN 100000 AND 599999
                THEN 'Kunde'
            WHEN a.adressnummer_num BETWEEN 600000 AND 699999
                THEN 'Präsident'
            WHEN a.adressnummer_num BETWEEN 700000 AND 890000
                THEN 'Kreditor'
            WHEN a.adressnummer_num >= 89999999
                THEN 'Erstkontakt'
            ELSE 'Sonstige'
        END AS klassifizierung

    FROM adressen AS a

    LEFT JOIN {{ ref('raw_vertreter') }} AS rv
        ON a.adr_vertreternummer::varchar(20) = rv.ver_vertreternummer::varchar(20)

),

umsatz AS (

    SELECT
        f.bel_final_adr_nr rechnung_adress_nr,

        SUM(
            CASE
                WHEN f.bel_date >= DATE_TRUNC('month', CURRENT_DATE)
                 AND f.bel_date < DATE_TRUNC('month', CURRENT_DATE)
                                            + INTERVAL '1 month'
                    THEN f.rechnung_umsatz_calc
                ELSE 0
            END
        ) AS umsatz_aktueller_monat,

        SUM(
            CASE
                WHEN f.bel_date >= CURRENT_DATE - INTERVAL '12 months'
                    THEN f.rechnung_umsatz_calc
                ELSE 0
            END
        ) AS umsatz_letzte_12_monate,

        MAX(f.bel_date) AS letzter_umsatz_am

    FROM {{ ref('gold_wencke_facts_belege_positionen') }} AS f

    WHERE mandant = 36

    GROUP BY
        f.bel_final_adr_nr

)

SELECT
    k.final_adress_nummer,
    k.final_name,
    k.adr_adresse,
    k.adr_plz,
    k.adr_stadt,
    k.adrgruppe_name,
    k.ver_vertreternummer,
    k.ver_vertretername,
    k.klassifizierung,

    COALESCE(u.umsatz_aktueller_monat, 0) AS umsatz_aktueller_monat,
    COALESCE(u.umsatz_letzte_12_monate, 0) AS umsatz_letzte_12_monate,
    u.letzter_umsatz_am,

    CASE
        WHEN COALESCE(u.umsatz_letzte_12_monate, 0) >= 25000
            THEN 'A-Kunde'
        WHEN COALESCE(u.umsatz_letzte_12_monate, 0) >= 10000
            THEN 'B-Kunde'
        WHEN COALESCE(u.umsatz_letzte_12_monate, 0) > 0
            THEN 'C-Kunde'
        ELSE 'Ohne Umsatz'
    END AS kundenklasse

FROM kunden AS k

LEFT JOIN umsatz AS u
    ON u.rechnung_adress_nr = k.final_adress_nummer

WHERE k.klassifizierung IN ('Kunde', 'Erstkontakt')