
{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_ids AS (

    SELECT DISTINCT
        art_artikelnummer

    FROM {{ ref('silver_wencke_artikel_attribute') }}

),

-- ============================================================
-- NORMALE ARTIKELATTRIBUTE
-- art_warengruppe bleibt unverändert
-- ============================================================

values_long AS (

    SELECT
        s.art_artikelnummer,
        v.field_name,
        v.value

    FROM {{ ref('silver_wencke_artikel_attribute') }} s

    CROSS JOIN LATERAL (

        VALUES
            ('art_artikelname', s.art_artikelname::text),
            ('art_warengruppe', s.art_warengruppe::text),

            ('art_herstellernummer', s.art_herstellernummer::text),

            ('art_lieferant', s.art_lieferant::text),
            ('art_lieferantbezeichnung', s.art_lieferantbezeichnung::text),

            ('art_divers_flag', s.art_divers_flag::text),

            ('art_ek_netto', s.art_ek_netto::text),
            ('art_lagereinheit', s.art_lagereinheit::text),

            ('art_bezeichnung_2', s.art_bezeichnung_2::text),
            ('art_bezeichnung_3', s.art_bezeichnung_3::text),
            ('art_bezeichnung_4', s.art_bezeichnung_4::text),

            ('art_artikel_ohne_temperaturgrenze', s.art_artikel_ohne_temperaturgrenze::text),
            ('art_temperaturgrenze_vorhanden', s.art_temperaturgrenze_vorhanden::text),

            ('art_lagertemperatur_von', s.art_lagertemperatur_von::text),
            ('art_lagertemperatur_bis', s.art_lagertemperatur_bis::text),

            ('art_transporttemperatur_von', s.art_transporttemperatur_von::text),
            ('art_transporttemperatur_bis', s.art_transporttemperatur_bis::text),

            ('art_sort_kz', s.art_sort_kz::text),
            ('art_pauschalartikel', s.art_pauschalartikel::text),
            ('art_pflege_divisor', s.art_pflege_divisor::text),
            ('art_abc_kategorie', s.art_abc_kategorie::text),

            ('art_gesperrter_artikel', s.art_gesperrter_artikel::text),
            ('art_auswahl_gesperrt', s.art_auswahl_gesperrt::text),

            ('art_gefahrstoff', s.art_gefahrstoff::text),
            ('art_artikelname_kurz', s.art_artikelname_kurz::text),

            ('art_nachhaltiger_artikel', s.art_nachhaltiger_artikel::text),
            ('art_nh_blauer_engel', s.art_nh_blauer_engel::text),
            ('art_nh_eu_ecolabel', s.art_nh_eu_ecolabel::text),
            ('art_nh_nordic_ecolabel', s.art_nh_nordic_ecolabel::text),
            ('art_nh_fsc', s.art_nh_fsc::text),
            ('art_nh_sonstiges', s.art_nh_sonstiges::text),
            ('art_nh_sonstiges_name', s.art_nh_sonstiges_name::text)

    ) v(field_name, value)

    WHERE v.value IS NOT NULL

),

-- ============================================================
-- HÄUFIGKEIT DER ARTIKELATTRIBUTE
-- ============================================================

scores AS (

    SELECT
        art_artikelnummer,
        field_name,
        value,
        COUNT(*) AS score

    FROM values_long

    GROUP BY
        art_artikelnummer,
        field_name,
        value

),

ranked AS (

    SELECT
        art_artikelnummer,
        field_name,
        value,

        ROW_NUMBER() OVER (

            PARTITION BY
                art_artikelnummer,
                field_name

            ORDER BY
                score DESC,
                LENGTH(value) DESC,
                value ASC

        ) AS rn

    FROM scores

),

golden_values AS (

    SELECT
        art_artikelnummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_artikelname'
        ) AS art_artikelname,

        MAX(value) FILTER (
            WHERE field_name = 'art_warengruppe'
        ) AS art_warengruppe,

        MAX(value) FILTER (
            WHERE field_name = 'art_herstellernummer'
        ) AS art_herstellernummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_lieferant'
        ) AS art_lieferant,

        MAX(value) FILTER (
            WHERE field_name = 'art_lieferantbezeichnung'
        ) AS art_lieferantbezeichnung,

        MAX(value) FILTER (
            WHERE field_name = 'art_divers_flag'
        ) AS art_divers_flag,

        MAX(value) FILTER (
            WHERE field_name = 'art_ek_netto'
        )::numeric AS art_ek_netto,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagereinheit'
        ) AS art_lagereinheit,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_2'
        ) AS art_bezeichnung_2,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_3'
        ) AS art_bezeichnung_3,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_4'
        ) AS art_bezeichnung_4,

        MAX(value) FILTER (
            WHERE field_name = 'art_artikel_ohne_temperaturgrenze'
        ) AS art_artikel_ohne_temperaturgrenze,

        MAX(value) FILTER (
            WHERE field_name = 'art_temperaturgrenze_vorhanden'
        ) AS art_temperaturgrenze_vorhanden,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagertemperatur_von'
        ) AS art_lagertemperatur_von,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagertemperatur_bis'
        ) AS art_lagertemperatur_bis,

        MAX(value) FILTER (
            WHERE field_name = 'art_transporttemperatur_von'
        ) AS art_transporttemperatur_von,

        MAX(value) FILTER (
            WHERE field_name = 'art_transporttemperatur_bis'
        ) AS art_transporttemperatur_bis,

        MAX(value) FILTER (
            WHERE field_name = 'art_sort_kz'
        ) AS art_sort_kz,

        MAX(value) FILTER (
            WHERE field_name = 'art_pauschalartikel'
        ) AS art_pauschalartikel,

        MAX(value) FILTER (
            WHERE field_name = 'art_pflege_divisor'
        ) AS art_pflege_divisor,

        MAX(value) FILTER (
            WHERE field_name = 'art_abc_kategorie'
        ) AS art_abc_kategorie,

        MAX(value) FILTER (
            WHERE field_name = 'art_gesperrter_artikel'
        ) AS art_gesperrter_artikel,

        MAX(value) FILTER (
            WHERE field_name = 'art_auswahl_gesperrt'
        ) AS art_auswahl_gesperrt,

        MAX(value) FILTER (
            WHERE field_name = 'art_gefahrstoff'
        ) AS art_gefahrstoff,

        MAX(value) FILTER (
            WHERE field_name = 'art_artikelname_kurz'
        ) AS art_artikelname_kurz,

        MAX(value) FILTER (
            WHERE field_name = 'art_nachhaltiger_artikel'
        ) AS art_nachhaltiger_artikel,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_blauer_engel'
        ) AS art_nh_blauer_engel,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_eu_ecolabel'
        ) AS art_nh_eu_ecolabel,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_nordic_ecolabel'
        ) AS art_nh_nordic_ecolabel,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_fsc'
        ) AS art_nh_fsc,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_sonstiges'
        ) AS art_nh_sonstiges,

        MAX(value) FILTER (
            WHERE field_name = 'art_nh_sonstiges_name'
        ) AS art_nh_sonstiges_name

    FROM ranked

    WHERE rn = 1

    GROUP BY
        art_artikelnummer

),

-- ============================================================
-- KATEGORIE-MAPPING AUS GOLD
-- Gleiche JOIN-Grundlage wie früher in Silver
-- ============================================================

hauptkategorie AS (

    SELECT DISTINCT
        mandant,
        hauptkategorie_nummer,
        hauptkategorie_name_harmonisiert,
        hauptkategorie_bezeichnung_harmonisiert

    FROM {{ ref('gold_wencke_artikel_kategorien') }}

),

nebenkategorie AS (

    SELECT DISTINCT
        mandant,
        nebenkategorie_nummer,
        nebenkategorie_name_harmonisiert,
        nebenkategorie_bezeichnung_harmonisiert

    FROM {{ ref('gold_wencke_artikel_kategorien') }}

),

-- ============================================================
-- KATEGORIEN BEREITS VOR DEM RANKING HARMONISIEREN
-- Nummern, Namen und Bezeichnungen gemeinsam übernehmen
-- ============================================================

kategorie_basis AS (

    SELECT
        s.art_artikelnummer,
        s.mandant,

        h.hauptkategorie_nummer
            AS art_hauptkategorie_nummer,

        h.hauptkategorie_name_harmonisiert
            AS art_hauptkategorie_name,

        h.hauptkategorie_bezeichnung_harmonisiert
            AS art_hauptkategorie_bezeichnung,

        n.nebenkategorie_nummer
            AS art_nebenkategorie_nummer,

        n.nebenkategorie_name_harmonisiert
            AS art_nebenkategorie_name,

        n.nebenkategorie_bezeichnung_harmonisiert
            AS art_nebenkategorie_bezeichnung

    FROM {{ ref('silver_wencke_artikel_attribute') }} s

    LEFT JOIN hauptkategorie h
        ON s.mandant = h.mandant
        AND s.art_hauptkategorie_nummer = h.hauptkategorie_nummer

    LEFT JOIN nebenkategorie n
        ON s.mandant = n.mandant
        AND s.art_nebenkategorie_nummer = n.nebenkategorie_nummer

),

-- ============================================================
-- 1. HÄUFIGSTE NEBENKATEGORIE JE ARTIKEL
-- ============================================================

nebenkategorie_scores AS (

    SELECT
        art_artikelnummer,
        art_nebenkategorie_nummer,

        COUNT(*) AS score

    FROM kategorie_basis

    WHERE art_nebenkategorie_nummer IS NOT NULL

    GROUP BY
        art_artikelnummer,
        art_nebenkategorie_nummer

),

nebenkategorie_ranked AS (

    SELECT
        art_artikelnummer,
        art_nebenkategorie_nummer,

        ROW_NUMBER() OVER (

            PARTITION BY art_artikelnummer

            ORDER BY
                score DESC,
                LENGTH(art_nebenkategorie_nummer::text) DESC,
                art_nebenkategorie_nummer::text ASC

        ) AS rn

    FROM nebenkategorie_scores

),

-- ============================================================
-- 2. HÄUFIGSTE VOLLSTÄNDIGE KATEGORIENKOMBINATION
--
-- Nummern, Namen und Bezeichnungen werden gemeinsam gezählt.
-- Haupt- und Nebenkategorie stammen aus derselben Zuordnung.
-- ============================================================

kategorie_scores AS (

    SELECT
        k.art_artikelnummer,

        k.art_hauptkategorie_nummer,
        k.art_hauptkategorie_name,
        k.art_hauptkategorie_bezeichnung,

        k.art_nebenkategorie_nummer,
        k.art_nebenkategorie_name,
        k.art_nebenkategorie_bezeichnung,

        COUNT(*) AS score

    FROM kategorie_basis k

    INNER JOIN nebenkategorie_ranked n
        ON k.art_artikelnummer = n.art_artikelnummer
        AND k.art_nebenkategorie_nummer = n.art_nebenkategorie_nummer
        AND n.rn = 1

    GROUP BY
        k.art_artikelnummer,

        k.art_hauptkategorie_nummer,
        k.art_hauptkategorie_name,
        k.art_hauptkategorie_bezeichnung,

        k.art_nebenkategorie_nummer,
        k.art_nebenkategorie_name,
        k.art_nebenkategorie_bezeichnung

),

-- ============================================================
-- 3. RANKING DER VOLLSTÄNDIGEN KOMBINATION
--
-- Wie in der alten Welt:
-- 1. Höchste Häufigkeit
-- 2. Längste Nebenkategoriebezeichnung
-- 3. Alphabetisch erste Nebenkategoriebezeichnung
-- ============================================================

kategorie_ranked AS (

    SELECT
        *,

        ROW_NUMBER() OVER (

            PARTITION BY art_artikelnummer

            ORDER BY
                score DESC,

                LENGTH(
                    COALESCE(
                        art_nebenkategorie_bezeichnung::text,
                        ''
                    )
                ) DESC,

                COALESCE(
                    art_nebenkategorie_bezeichnung::text,
                    ''
                ) ASC

        ) AS rn

    FROM kategorie_scores

),

-- ============================================================
-- 4. GOLDEN CATEGORY
-- ============================================================

golden_kategorie AS (

    SELECT
        art_artikelnummer,

        art_hauptkategorie_nummer,
        art_hauptkategorie_name,
        art_hauptkategorie_bezeichnung,

        art_nebenkategorie_nummer,
        art_nebenkategorie_name,
        art_nebenkategorie_bezeichnung

    FROM kategorie_ranked

    WHERE rn = 1

),

-- ============================================================
-- TOS
-- ============================================================

tos AS (

    SELECT DISTINCT
        ar_text AS art_artikelnummer

    FROM {{ ref('bronze_wencke_tos_artikel_attribut') }}

    WHERE ar_art = 1389

)

-- ============================================================
-- FINAL
-- ============================================================

SELECT

    base.art_artikelnummer,

    g.art_artikelname,

    base.art_artikelnummer
        || '-'
        || COALESCE(g.art_artikelname, '')
        AS art_bezeichnung,

    -- Unverändert
    g.art_warengruppe,

    -- ========================================================
    -- HAUPTKATEGORIE
    -- ========================================================

    k.art_hauptkategorie_nummer,
    k.art_hauptkategorie_name,
    k.art_hauptkategorie_bezeichnung,

    -- ========================================================
    -- NEBENKATEGORIE
    -- ========================================================

    k.art_nebenkategorie_nummer,
    k.art_nebenkategorie_name,
    k.art_nebenkategorie_bezeichnung,

    -- ========================================================
    -- HERSTELLER UND LIEFERANT
    -- ========================================================

    g.art_herstellernummer,

    g.art_lieferant,
    g.art_lieferantbezeichnung,

    -- ========================================================
    -- PREISE UND ARTIKELATTRIBUTE
    -- ========================================================

    g.art_divers_flag,
    g.art_ek_netto,

    g.art_lagereinheit,

    g.art_bezeichnung_2,
    g.art_bezeichnung_3,
    g.art_bezeichnung_4,

    -- ========================================================
    -- TEMPERATUR
    -- ========================================================

    g.art_artikel_ohne_temperaturgrenze,
    g.art_temperaturgrenze_vorhanden,

    g.art_lagertemperatur_von,
    g.art_lagertemperatur_bis,

    g.art_transporttemperatur_von,
    g.art_transporttemperatur_bis,

    -- ========================================================
    -- WEITERE ARTIKELATTRIBUTE
    -- ========================================================

    g.art_sort_kz,
    g.art_pauschalartikel,
    g.art_pflege_divisor,
    g.art_abc_kategorie,

    g.art_gesperrter_artikel,
    g.art_auswahl_gesperrt,

    g.art_gefahrstoff,
    g.art_artikelname_kurz,

    -- ========================================================
    -- NACHHALTIGKEIT
    -- ========================================================

    g.art_nachhaltiger_artikel,
    g.art_nh_blauer_engel,
    g.art_nh_eu_ecolabel,
    g.art_nh_nordic_ecolabel,
    g.art_nh_fsc,
    g.art_nh_sonstiges,
    g.art_nh_sonstiges_name,

    -- ========================================================
    -- TOS
    -- ========================================================

    CASE
        WHEN tos.art_artikelnummer IS NOT NULL
            THEN 'J'
        ELSE 'N'
    END AS art_tos_verfuegbar

FROM artikel_ids base

LEFT JOIN golden_values g
    ON base.art_artikelnummer = g.art_artikelnummer

LEFT JOIN golden_kategorie k
    ON base.art_artikelnummer = k.art_artikelnummer

LEFT JOIN tos
    ON base.art_artikelnummer = tos.art_artikelnummer
