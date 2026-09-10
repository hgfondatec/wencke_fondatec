{{
    config(
        materialized = 'table',
        tags = ['artikel']
    )
}}

SELECT
    kategorie_nr,
    mandant,
    wencke_id,
    is_hauptkategorie,
    kat_bezeichnung,
    kat_suchindex_1,
    kat_suchindex_2,
    kat_suchindex_3,
    kat_suchindex_4,
    kat_suchindex_5,
    kat_positionserfassung,
    kat_einzelkalkulation,
    kat_anzahl_positionen,
    kat_erfassungstabelle,
    kat_aenderungsflag_dbk_dbp,
    kat_wfl_script,
    kat_wfl_verarbeitung,
    kat_wechsel_kartenummer,
    kat_logo_hauptkategorie,
    kat_werbebild_a4,
    kat_erfasst_von,
    kat_geaendert_von,
    created_at,
    updated_at,
    source_hash

FROM {{ source('raw', 'wencke_lv_artikel_kategorien') }}