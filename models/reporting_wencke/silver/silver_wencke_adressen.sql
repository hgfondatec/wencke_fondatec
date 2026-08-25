{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH adresse AS (

    SELECT
        a.wencke_id,
        a.mandant,
        a.adr_nr,
        a.adr_kurzname,
        a.adr_kurzbez,
        a.adr_suchbegriff,
        a.adr_adressart,
        a.adr_adresstyp,
        a.adr_adressgruppe,
        a.adr_parent_adr,
        a.adr_re_empfaenger_nr,

        CONCAT(
            a.adr_nr,
            '-',
            COALESCE(a.adr_firmenname, ''),
            ' ',
            COALESCE(a.adr_firmenname2, ''),
            ' ',
            COALESCE(a.adr_firmenname3, '')
        ) AS adr_text,

        a.adr_gesperrt_neue_belege,
        a.adr_firmenname,
        a.adr_firmenname2,
        a.adr_firmenname3,
        a.adr_strasse,
        a.adr_plz,
        a.adr_ort,
        a.adr_ortszusatz,
        a.adr_land,
        a.adr_bundesland,
        a.adr_telefon,
        a.adr_telefax,
        a.adr_mobil,
        a.adr_email,
        a.adr_vertreter_nr,
        a.adr_hauptvertreter_nr,
        a.adr_abc_kunde,
        a.adr_skonto1_prozent,
        a.adr_sort_kz,

        serv.adr_servicehandbuch_vorhanden,
        serv.adr_servicehandbuch_jahr,
        serv.adr_servicehandbuch_monat,
        serv.adr_servicehandbuch_datum,
        serv.adr_dosiertechnik,
        serv.adr_serviceintervall_anzahl_jaehrlich,
        serv.adr_schulung,
        serv.adr_letzte_schulung_jahr,
        serv.adr_letzte_schulung_monat,
        serv.adr_haende_hygieneplan_vorhanden,
        serv.adr_gefahrstoffverzeichnis,

        hc.heim AS heim_adr_nr,
        h.adr_firmenname as heim_firmenname,

        CONCAT(
            p1.adr_nr,
            '-',
            COALESCE(p1.adr_firmenname, ''))
         AS praesident_ebene_1_bezeichnung,

         CONCAT(
            p2.adr_nr,
            '-',
            COALESCE(p2.adr_firmenname, ''))
         AS praesident_ebene_2_bezeichnung,

         CONCAT(
            p3.adr_nr,
            '-',
            COALESCE(p3.adr_firmenname, ''))
         AS praesident_ebene_3_bezeichnung,

        hc.pflegekasse AS pflegekasse_adr_nr,

        CONCAT(
            hc.pflegekasse,
            '-',
            COALESCE(kk.adr_firmenname, ''))
         AS pflegekasse_text,

        a.adr_re_empfaenger_nr AS re_empfaenger_adr_nr,

        CONCAT(
            a.adr_re_empfaenger_nr,
            '-',
            COALESCE(re.adr_firmenname, ''))
         AS re_empfaenger_firmenname,

        i.topserv_statistik_nr,
        i.topserv_lieferanten_nr

    FROM {{ ref('bronze_wencke_adressen') }} AS a

    LEFT JOIN {{ ref('bronze_wencke_adressen_healthcare') }} AS hc
        ON a.wencke_id = hc.wencke_id

    LEFT JOIN {{ ref('bronze_wencke_adressen_identifikatoren') }} AS i
        ON a.wencke_id = i.wencke_id

    LEFT JOIN {{ ref('bronze_wencke_adressen_service') }} AS serv
        ON a.wencke_id = serv.wencke_id

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS h
        ON hc.heim = h.adr_nr
        AND a.mandant = h.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS kk
        ON hc.pflegekasse = kk.adr_nr
        AND a.mandant = kk.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS re
        ON a.adr_re_empfaenger_nr = re.adr_nr
        AND a.mandant = re.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p3
        ON a.adr_parent_adr = p3.adr_nr
        AND a.mandant = p3.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p2
        ON p3.adr_parent_adr = p2.adr_nr
        AND p3.mandant = p2.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p1
        ON p2.adr_parent_adr = p1.adr_nr
        AND p2.mandant = p1.mandant

)

SELECT *
FROM adresse