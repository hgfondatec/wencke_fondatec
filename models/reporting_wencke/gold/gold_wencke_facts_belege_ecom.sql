{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


WITH belege AS (
    SELECT
        wencke_id,
        mandant,
        bel_date,
        bel_herkunft,
        bel_ecom_id
    FROM {{ ref('silver_wencke_belege_rechnung_gutschrift') }}
),
basis AS (
    SELECT
        mandant,
        DATE_TRUNC('month', bel_date)::date AS monat,
        bel_ecom_id,
        bel_herkunft,
        CASE bel_herkunft::text
            WHEN '1' THEN 'Telefon'
            WHEN '2' THEN 'Fax'
            WHEN '3' THEN 'E-Mail'
            WHEN '4' THEN 'Pflegemesse Essen 2026'
            WHEN '5' THEN 'Außendienst'
            WHEN '6' THEN 'schriftlich'
            WHEN '7' THEN 'persönlich'
            WHEN '8' THEN 'Hersteller-Aussendienst'
            WHEN '9' THEN 'Rezept'
            WHEN '10' THEN 'Weiterberechnung'
            WHEN '11' THEN 'schriftl. / Ausschreibung'
            WHEN '12' THEN 'Abverkauf Altware'
            WHEN '13' THEN 'Fahrer'
            WHEN '14' THEN 'Neuerf./Auftr.nicht im System'
            WHEN '15' THEN 'Nachberechnung'
            WHEN '16' THEN 'Partner'
            WHEN '17' THEN 'Anrufbeantworter'
            WHEN '18' THEN 'Nacherfassung w/ Reklam'
            WHEN '19' THEN 'Lagermeister'
            WHEN '20' THEN 'Sammel-Rechnung'
            WHEN '21' THEN 'Dauerauftrag'
            WHEN '22' THEN 'Selbstabholer'
            WHEN '23' THEN 'Reklamation'
            WHEN '24' THEN 'L1 --> L2'
            WHEN '25' THEN 'L2 --> L1'
            WHEN '26' THEN 'Techniker'
            WHEN '27' THEN 'Abruf zu Vorabrechnung'
            WHEN '28' THEN 'Neuerfassung'
            WHEN '29' THEN 'WhatsApp'
            WHEN '30' THEN 'MOPP-Erfassung (auto/manuell)'
            WHEN '31' THEN 'Hausmesse 2017'
            WHEN '32' THEN 'Vorkasse'
            WHEN '34' THEN 'Videokonferenz'
            WHEN '35' THEN 'Hausmesse 2023'
            WHEN '36' THEN 'Aktionsflyer'
            WHEN '37' THEN 'MDE-Test-Auftrag'
            WHEN '38' THEN 'Hausmesse 2026'
            WHEN '40' THEN 'Diebstahl'
            WHEN '41' THEN 'Altware vernichtet'
            WHEN '42' THEN 'Bruch defekt'
            WHEN '43' THEN 'Pendel'
            WHEN '44' THEN 'LENGOW'
            WHEN '49' THEN 'Hogast'
            WHEN '50' THEN 'Sensano'
            WHEN '51' THEN 'GHX'
            WHEN '52' THEN 'WISAG'
            WHEN '53' THEN 'GSG'
            WHEN '54' THEN 'Simple System'
            WHEN '55' THEN 'Atlantic Hotels'
            WHEN '56' THEN 'Newtron'
            WHEN '57' THEN 'Selly'
            WHEN '58' THEN 'Paritätische Lebenshilfe'
            WHEN '59' THEN 'Mercateo'
            WHEN '60' THEN 'Fa. Zimmermann'
            WHEN '61' THEN 'Techniker Herr Wikowski'
            WHEN '62' THEN 'Nachlieferung'
            WHEN '66' THEN 'Uniserve'
            WHEN '67' THEN 'Lieblang'
            WHEN '68' THEN 'TOS (neu)'
            WHEN '69' THEN 'ADU'
            WHEN '70' THEN 'PEG (neu)'
            WHEN '71' THEN 'HSB Kleine'
            WHEN '72' THEN 'LZN'
            WHEN '73' THEN 'TipTop'
            WHEN '74' THEN 'Median Kliniken'
            WHEN '75' THEN 'Progros'
            WHEN '76' THEN 'Top Gebäudereinigung'
            WHEN '77' THEN 'GDA'
            WHEN '78' THEN 'Helios'
            WHEN '79' THEN 'Book a Tiger'
            WHEN '80' THEN 'Burchard Führer'
            WHEN '81' THEN 'OM Auftrag neu'
            WHEN '82' THEN 'OM Auftrag alt'
            WHEN '83' THEN 'Shop'
            WHEN '84' THEN 'Shop extern'
            WHEN '85' THEN 'ZF an Partner'
            WHEN '86' THEN 'ZF von Partner'
            WHEN '87' THEN 'OM Preisanfrage'
            WHEN '88' THEN 'TOS Preisanfrage'
            WHEN '89' THEN 'Bestellung Zentrallager'
            WHEN '90' THEN 'Sanitätshaus'
            WHEN '91' THEN 'Thomas ID'
            WHEN '92' THEN 'Thomas GR'
            WHEN '93' THEN 'OptaData'
            WHEN '94' THEN 'Clinicpartner'
            WHEN '95' THEN 'HBS (AGKAMED)'
            WHEN '96' THEN 'SaniUp'
            WHEN '97' THEN 'PCM'
            WHEN '98' THEN 'Lobster Datagroup'
            WHEN '99' THEN 'Reklamation'
            ELSE 'Unbekannt (' || COALESCE(bel_herkunft::text, 'NULL') || ')'
        END AS herkunft
    FROM belege
)
SELECT
    mandant,
    monat,
    bel_herkunft AS herkunft_nr,
    herkunft,
    COUNT(*) FILTER (
        WHERE bel_ecom_id IS NOT NULL
            AND TRIM(bel_ecom_id::text) <> ''
    ) AS ecom_belege,
    COUNT(*) AS gesamt_belege
FROM basis
GROUP BY
    mandant,
    monat,
    bel_herkunft,
    herkunft
ORDER BY
    mandant,
    monat,
    bel_herkunft