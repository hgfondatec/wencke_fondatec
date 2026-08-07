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

        hc.heim AS heim_adr_nr,
        h.heim_firmenname,
        h.praesident_ebene_1_bezeichnung,
        h.praesident_ebene_2_bezeichnung,
        h.praesident_ebene_3_bezeichnung,

        hc.pflegekasse AS pflegekasse_adr_nr,
        kk.pflegekasse_text,

        a.adr_re_empfaenger_nr AS re_empfaenger_adr_nr,
        re.re_empfaenger_firmenname

    FROM {{ ref('bronze_wencke_adressen') }} AS a

    LEFT JOIN {{ ref('bronze_wencke_adressen_healthcare') }} AS hc
        ON a.wencke_id = hc.wencke_id

    LEFT JOIN {{ ref('silver_wencke_adressen_heim') }} AS h
        ON hc.heim = h.heim_adr_nr
        AND a.mandant = h.mandant

    LEFT JOIN {{ ref('silver_wencke_adressen_krankenkassen') }} AS kk
        ON hc.pflegekasse = kk.adr_nr
        AND a.mandant = kk.mandant

    LEFT JOIN {{ ref('silver_wencke_adressen_re_empfaenger') }} AS re
        ON a.adr_re_empfaenger_nr = re.adr_nr
        AND a.mandant = re.mandant

)

SELECT *
FROM adresse