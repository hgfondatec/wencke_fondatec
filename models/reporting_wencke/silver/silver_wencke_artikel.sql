{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel AS (

    SELECT
        wencke_id,
        mandant,
        artikel_nr,
        art_warengruppe,
        art_artikelname,
        art_bezeichnung_2,
        art_bezeichnung_3,
        art_bezeichnung_4,
        art_hauptkategorie_id,
        art_nebenkategorie_id,
        adr_lieferant_1,
        art_ek_netto,
        art_herstellernummer,
        art_pauschalartikel,
        art_lagereinheit,
        art_abc_kategorie,
        art_divers_flag,
        art_artikelname_kurz,
        art_sort_kz,
        art_pflege_divisor,
        art_gesperrter_artikel,
        art_auswahl_gesperrt

    FROM {{ ref('bronze_wencke_artikel_attribute') }}

),

temperatur AS (

    SELECT
        wencke_id,
        art_artikel_ohne_temperaturgrenze,
        art_temperaturgrenze_vorhanden,
        art_lagertemperatur_von,
        art_lagertemperatur_bis,
        art_transporttemperatur_von,
        art_transporttemperatur_bis

    FROM {{ ref('bronze_wencke_artikel_attribute_temp') }}

),

gefahr AS (

    SELECT
        wencke_id,
        art_gefahrstoff

    FROM {{ ref('bronze_wencke_artikel_attribute_gefahr') }}

),

lieferant AS (

    SELECT
        wencke_id,
        art_lieferant,
        art_lieferantbezeichnung

    FROM {{ ref('silver_wencke_lieferant_artikel') }}

),

hauptwarengruppe AS (

    SELECT
        32 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('lloyd_silver_hauptwarengruppe') }}

    UNION ALL

    SELECT
        36 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('nonne_silver_hauptwarengruppe') }}

    UNION ALL

    -- Kernreich: Warengruppentabelle noch nicht vorhanden
    SELECT
        38 AS mandant,
        NULL::varchar AS wg_nummer,
        NULL::varchar AS wg_name
    WHERE FALSE

    UNION ALL

    SELECT
        39 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('glasofix_silver_hauptwarengruppe') }}

    UNION ALL

    SELECT
        42 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('vms_silver_hauptwarengruppe') }}

),

nebenwarengruppe AS (

    SELECT
        32 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('lloyd_silver_nebenwarengruppe') }}

    UNION ALL

    SELECT
        36 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('nonne_silver_nebenwarengruppe') }}

    UNION ALL

    -- Kernreich: Warengruppentabelle noch nicht vorhanden
    SELECT
        38 AS mandant,
        NULL::varchar AS wg_nummer,
        NULL::varchar AS wg_name
    WHERE FALSE

    UNION ALL

    SELECT
        39 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('glasofix_silver_nebenwarengruppe') }}

    UNION ALL

    SELECT
        42 AS mandant,
        wg_nummer,
        wg_name
    FROM {{ ref('vms_silver_nebenwarengruppe') }}

)

SELECT

    a.wencke_id,
    a.mandant,
    a.artikel_nr AS art_artikelnummer,

    a.art_artikelname,
    a.art_warengruppe,

    a.artikel_nr || '-' || a.art_artikelname
        AS art_bezeichnung,

    h.wg_nummer AS art_hauptwarengruppe_nummer,
    h.wg_name AS art_hauptwarengruppe,

    CASE
        WHEN h.wg_nummer IS NOT NULL
         AND h.wg_name IS NOT NULL
        THEN h.wg_nummer || '-' || h.wg_name
        ELSE NULL
    END AS art_hauptwarenbezeichnung,

    n.wg_nummer AS art_nebenwarengruppe_nummer,
    n.wg_name AS art_nebenwarengruppe,

    CASE
        WHEN n.wg_nummer IS NOT NULL
         AND n.wg_name IS NOT NULL
        THEN n.wg_nummer || '-' || n.wg_name
        ELSE NULL
    END AS art_nebenwarengruppebezeichnung,

    a.art_herstellernummer,

    a.adr_lieferant_1,
    l.art_lieferant,
    l.art_lieferantbezeichnung,

    a.art_divers_flag,
    a.art_ek_netto,
    a.art_lagereinheit,

    a.art_bezeichnung_2,
    a.art_bezeichnung_3,
    a.art_bezeichnung_4,

    t.art_artikel_ohne_temperaturgrenze,
    t.art_temperaturgrenze_vorhanden,
    t.art_lagertemperatur_von,
    t.art_lagertemperatur_bis,
    t.art_transporttemperatur_von,
    t.art_transporttemperatur_bis,

    a.art_sort_kz,
    a.art_pauschalartikel,
    a.art_pflege_divisor,
    a.art_abc_kategorie,

    a.art_gesperrter_artikel,
    a.art_auswahl_gesperrt,

    g.art_gefahrstoff

FROM artikel a

LEFT JOIN temperatur t
    ON a.wencke_id = t.wencke_id

LEFT JOIN gefahr g
    ON a.wencke_id = g.wencke_id

LEFT JOIN lieferant l
    ON a.wencke_id = l.wencke_id

LEFT JOIN hauptwarengruppe h
    ON a.mandant = h.mandant
    AND a.art_hauptkategorie_id = h.wg_nummer

LEFT JOIN nebenwarengruppe n
    ON a.mandant = n.mandant
    AND a.art_nebenkategorie_id = n.wg_nummer