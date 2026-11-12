
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

        -- Kategorienummern
        art_hauptkategorie_id,
        art_nebenkategorie_id,

        adr_lieferant_1,
        art_ek_netto,

        -- Verkaufspreise
        art_vk_1,
        art_vk_2,
        art_vk_3,

        art_herstellernummer,
        art_pauschalartikel,
        art_lagereinheit,
        art_abc_kategorie,
        art_divers_flag,
        art_artikelname_kurz,
        art_sort_kz,
        art_pflege_divisor,
        art_gesperrter_artikel,
        art_auswahl_gesperrt,

        -- Nachhaltigkeit
        art_nachhaltiger_artikel,
        art_nh_blauer_engel,
        art_nh_eu_ecolabel,
        art_nh_nordic_ecolabel,
        art_nh_fsc,
        art_nh_sonstiges,
        art_nh_sonstiges_name,
        art_nh_bitmap

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

    FROM {{ ref('silver_wencke_artikel_lieferant') }}

)

SELECT

    -- ==================================================
    -- ARTIKELSTAMMDATEN
    -- ==================================================

    a.wencke_id,
    a.mandant,

    a.artikel_nr AS art_artikelnummer,

    a.art_artikelname,

    -- Unverändertes Artikelattribut
    a.art_warengruppe,

    a.artikel_nr || '-' || a.art_artikelname
        AS art_bezeichnung,

    -- ==================================================
    -- HAUPTKATEGORIE
    -- ==================================================

    a.art_hauptkategorie_id
        AS art_hauptkategorie_nummer,

    -- ==================================================
    -- NEBENKATEGORIE
    -- ==================================================

    a.art_nebenkategorie_id
        AS art_nebenkategorie_nummer,

    -- ==================================================
    -- HERSTELLER UND LIEFERANT
    -- ==================================================

    a.art_herstellernummer,

    a.adr_lieferant_1,

    l.art_lieferant,
    l.art_lieferantbezeichnung,

    -- ==================================================
    -- PREISE
    -- ==================================================

    a.art_divers_flag,
    a.art_ek_netto,

    a.art_vk_1,
    a.art_vk_2,
    a.art_vk_3,

    -- ==================================================
    -- ARTIKELATTRIBUTE
    -- ==================================================

    a.art_lagereinheit,

    a.art_bezeichnung_2,
    a.art_bezeichnung_3,
    a.art_bezeichnung_4,

    -- ==================================================
    -- TEMPERATUR
    -- ==================================================

    t.art_artikel_ohne_temperaturgrenze,
    t.art_temperaturgrenze_vorhanden,
    t.art_lagertemperatur_von,
    t.art_lagertemperatur_bis,
    t.art_transporttemperatur_von,
    t.art_transporttemperatur_bis,

    -- ==================================================
    -- WEITERE ARTIKELMERKMALE
    -- ==================================================

    a.art_sort_kz,
    a.art_pauschalartikel,
    a.art_pflege_divisor,
    a.art_abc_kategorie,
    a.art_artikelname_kurz,

    a.art_gesperrter_artikel,
    a.art_auswahl_gesperrt,

    g.art_gefahrstoff,

    -- ==================================================
    -- NACHHALTIGKEIT
    -- ==================================================

    a.art_nachhaltiger_artikel,
    a.art_nh_blauer_engel,
    a.art_nh_eu_ecolabel,
    a.art_nh_nordic_ecolabel,
    a.art_nh_fsc,
    a.art_nh_sonstiges,
    a.art_nh_sonstiges_name,
    a.art_nh_bitmap

FROM artikel a

LEFT JOIN temperatur t
    ON a.wencke_id = t.wencke_id

LEFT JOIN gefahr g
    ON a.wencke_id = g.wencke_id

LEFT JOIN lieferant l
    ON a.wencke_id = l.wencke_id
