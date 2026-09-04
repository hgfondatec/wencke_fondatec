{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['bestand']
    )
}}

WITH bestand AS (

    SELECT
        wencke_id,
        lager,
        art_bestand,
        art_beauftragt,
        art_verfuegbar,
        art_bestellt,
        art_bestelltzum,
        art_naechster_bestelltermin,
        art_naechste_bestellmenge,
        art_ueberbestand,
        art_mindestbestand,
        art_reichweite
    FROM {{ ref('bronze_wencke_artikel_bestand') }}

),

artikel AS (

    SELECT
        wencke_id,
        mandant,
        artikel_nr,
        art_ek_netto,
        art_lagereinheit,
        art_gesperrter_artikel,
        art_auswahl_gesperrt
    FROM {{ ref('bronze_wencke_artikel_attribute') }}

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
        art_lieferantbezeichnung
    FROM {{ ref('silver_wencke_lieferant_artikel') }}

)

SELECT
    a.artikel_nr::varchar(255) AS artikelnummer,
    a.art_ek_netto::float8 AS art_ek_netto,
    a.art_lagereinheit::varchar(10) AS art_lagereinheit,
    l.art_lieferantbezeichnung::varchar(6) AS lieferantenbezeichnung,
    a.art_gesperrter_artikel::varchar(1) AS gesperrter_artikel,
    a.art_auswahl_gesperrt::varchar(1) AS auswahl_gesperrt,
    g.art_gefahrstoff::varchar(1) AS gefahrstoff,
    b.lager::varchar(10) AS lager_id,
    b.art_bestand::float8 AS lagerbestand,
    b.art_beauftragt::float8 AS beauftragt,
    b.art_verfuegbar::float8 AS verfuegbar,
    b.art_bestellt::float8 AS bestellt,
    b.art_bestelltzum::varchar(255) AS bestelltzum,
    b.art_naechster_bestelltermin::varchar(255) AS naechster_bestelltermin,
    b.art_naechste_bestellmenge::float8 AS naechste_bestellmenge,
    b.art_ueberbestand::varchar(1) AS ueberbestand,
    b.art_mindestbestand::float8 AS mindestbestand,
    b.art_reichweite::float8 AS reichweite,
    a.mandant::varchar(10) AS mandant_id,

    CONCAT(
        a.mandant,
        '_',
        b.lager
    )::varchar(20) AS mandant_lager_key

FROM bestand AS b

LEFT JOIN artikel AS a
    ON b.wencke_id = a.wencke_id

LEFT JOIN gefahr AS g
    ON b.wencke_id = g.wencke_id

LEFT JOIN lieferant AS l
    ON b.wencke_id = l.wencke_id