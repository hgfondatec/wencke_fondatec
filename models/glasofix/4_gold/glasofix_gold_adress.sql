{{ config(materialized='table') }}

WITH belege AS (
    SELECT DISTINCT
        CASE
            WHEN NULLIF(TRIM(bel_projektnummer), '') IS NOT NULL
                THEN NULLIF(TRIM(bel_heim), '')
            ELSE TRIM(bel_adressnummer)
        END AS belege_adress_nr
    FROM {{ ref('glasofix_bronze_belege') }}
),
adressen AS (
    SELECT distinct
        adr_adressnummer,
        adr_name,
        adr_name_2,
        adr_name_3,
        adr_heim,
        adr_krankenkasse,
        adr_rechnungsempfaenger,
        TRIM(adr_vertreternummer) as adr_vertreternummer,
        adr_adresse,
        adr_plz,
        adr_stadt,
        adr_nummer,
        adr_adresstyp,
        adr_servicehandbuch_vorhanden,
        adr_servicehandbuch_jahr,
        adr_servicehandbuch_monat,
        adr_dosiertechnik,
        adr_serviceintervall_anzahl_jaehrlich,
        adr_schulung,
        adr_letzte_schulung_jahr,
        adr_letzte_schulung_monat,
        adr_haende_hygieneplan_vorhanden,
        adr_gefahrstoffverzeichnis
    FROM {{ ref('glasofix_bronze_adresse') }}
),
heim AS (
    SELECT
        TRIM(heim_id) heim_id,
        heim_name,
        heim_bezeichnung,
        heim_praesident_3,
        heim_praesident_2,
        heim_praesident_1
    FROM {{ ref('glasofix_silver_heim') }}
),
rechnungsempfaenger AS (
    SELECT
        rechnungsempfaenger_id,
        rechnungsempfaenger_bezeichnung
    FROM {{ ref('glasofix_silver_re_empfaenger') }}
),
adressgruppe AS (
    SELECT
        adrgruppe_id,
        adrgruppe_name
    FROM {{ ref('glasofix_bronze_adressgruppe') }}
),
final AS (
    SELECT DISTINCT
        b.belege_adress_nr AS mapping_adressnummer,
        b.belege_adress_nr AS final_adress_nummer,
        COALESCE(a.adr_name, 'keine Bezeichnung') AS final_name,
        COALESCE(a.adr_name_2, 'keine Bezeichnung') AS final_name_2,
        COALESCE(a.adr_name_3, 'keine Bezeichnung') AS final_name_3,
        CAST(b.belege_adress_nr AS VARCHAR(10))
            || '-' || COALESCE(a.adr_name, 'keine Bezeichnung') AS final_adress_name,
        a.adr_adresse,
        a.adr_plz,
        a.adr_stadt,
        a.adr_nummer,
        a.adr_vertreternummer,
        a.adr_servicehandbuch_vorhanden,
        a.adr_servicehandbuch_jahr,
        a.adr_servicehandbuch_monat,
        a.adr_dosiertechnik,
        a.adr_serviceintervall_anzahl_jaehrlich,
        a.adr_schulung,
        a.adr_letzte_schulung_jahr,
        a.adr_letzte_schulung_monat,
        a.adr_haende_hygieneplan_vorhanden,
        a.adr_gefahrstoffverzeichnis,
        CAST(ag.adrgruppe_id as varchar(2)) as adrgruppe_id,
        ag.adrgruppe_name,
        r.rechnungsempfaenger_id,
        r.rechnungsempfaenger_bezeichnung,
        h.heim_praesident_3 AS praesident_3,
        h.heim_praesident_2 AS praesident_2,
        h.heim_praesident_1 AS praesident_1
    FROM belege b
    LEFT JOIN adressen a
        ON CAST(TRIM(b.belege_adress_nr) AS VARCHAR(10)) = TRIM(a.adr_adressnummer)
    LEFT JOIN heim h
        ON h.heim_id = b.belege_adress_nr
    LEFT JOIN rechnungsempfaenger r
        ON r.rechnungsempfaenger_id = a.adr_rechnungsempfaenger
    LEFT JOIN adressgruppe ag
        ON a.adr_adresstyp::TEXT = ag.adrgruppe_id::TEXT
)
SELECT *
FROM final