{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH heim AS (

    SELECT DISTINCT
        hc.heim,
        a.mandant
    FROM {{ ref('bronze_wencke_adressen_healthcare') }} AS hc
    INNER JOIN {{ ref('bronze_wencke_adressen') }} AS a
        ON hc.wencke_id = a.wencke_id
    WHERE hc.heim IS NOT NULL

),

adresse AS (

    SELECT
        adr.wencke_id,
        h.mandant,
        adr.adr_nr AS heim_adr_nr,
        adr.adr_firmenname,
        CONCAT(
            adr.adr_nr,
            '-',
            COALESCE(adr.adr_firmenname, 'keine Bezeichnung'),
            ' ',
            COALESCE(adr.adr_firmenname2, '')
        ) AS heim_firmenname,
        adr.adr_parent_adr
    FROM heim AS h
    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS adr
        ON h.heim = adr.adr_nr
        AND h.mandant = adr.mandant

),

praesidenten AS (

    SELECT
        adr.wencke_id,
        adr.mandant,
        adr.heim_adr_nr,
        adr.adr_firmenname,
        adr.heim_firmenname,

        p1.adr_nr AS praesident_ebene_1_adr_nr,
        p1.adr_firmenname AS praesident_ebene_1,
        CONCAT(
            p1.adr_nr,
            '-',
            COALESCE(p1.adr_firmenname, 'keine Bezeichnung')
        ) AS praesident_ebene_1_bezeichnung,

        p2.adr_nr AS praesident_ebene_2_adr_nr,
        p2.adr_firmenname AS praesident_ebene_2,
        CONCAT(
            p2.adr_nr,
            '-',
            COALESCE(p2.adr_firmenname, 'keine Bezeichnung')
        ) AS praesident_ebene_2_bezeichnung,

        p3.adr_nr AS praesident_ebene_3_adr_nr,
        p3.adr_firmenname AS praesident_ebene_3,
        CONCAT(
            p3.adr_nr,
            '-',
            COALESCE(p3.adr_firmenname, 'keine Bezeichnung')
        ) AS praesident_ebene_3_bezeichnung

    FROM adresse AS adr

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p3
        ON adr.adr_parent_adr = p3.adr_nr
        AND adr.mandant = p3.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p2
        ON p3.adr_parent_adr = p2.adr_nr
        AND p3.mandant = p2.mandant

    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS p1
        ON p2.adr_parent_adr = p1.adr_nr
        AND p2.mandant = p1.mandant

)

SELECT *
FROM praesidenten