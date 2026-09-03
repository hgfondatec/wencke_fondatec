{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT

    artikel_nr,
    mandant,
    wencke_id,

    art_kurzname,
    art_artikelname,
    art_bezeichnung_2,
    art_bezeichnung_3,
    art_bezeichnung_4,
    art_artikelname_kurz,
    art_suchindex,

    art_warengruppe,
    art_warengruppe_alt,
    art_hauptkategorie_id,
    art_nebenkategorie_id,
    art_hauptkategorie_pim,
    art_nebenkategorie_pim,

    art_sektor,
    art_sortiment,
    art_abc_kategorie,
    art_sort_kz,

    art_ean_code,
    art_standard_ean,
    art_menge_ean_code,
    art_pzn,
    art_hilfsmittel_nr,
    art_herstellernummer,
    art_artikel_partner,

    adr_lieferant_1,
    adr_lieferant_2,
    adr_lieferant_3,
    adr_lieferant_4,
    adr_lieferant_5,

    art_ek_netto,
    art_vk_1,
    art_vk_2,
    art_vk_3,
    art_vk_4,
    art_vk_5,
    art_fap,
    art_skew,
    art_ekst,
    art_rw,

    art_vk_alt_1,
    art_vk_alt_2,
    art_vk_alt_3,
    art_vk_alt_4,
    art_vk_alt_5,
    art_fap_alt,

    art_gewicht,
    art_gewicht_brutto,
    art_tara,
    art_inhalt,
    art_inhalt_angebotsdruck,
    art_menge_in_liter,
    art_dichte,
    art_masseinheit_dichte,

    art_lagereinheit,
    art_artikelpreiseinheit,
    art_paletteninhalt,
    art_divisor_ecolab,
    art_pflege_divisor,

    art_arzneimittel,
    art_medizinprodukt,
    art_mdr_produkt,
    art_mdr_klasse,
    art_apothekenpflichtig,
    art_produktart_302,
    art_kz_himi,
    art_sterilartikel,
    art_kennzeichnungsfrei,
    art_konformitaetserklaerung,

    art_nachhaltiger_artikel,
    art_nh_blauer_engel,
    art_nh_eu_ecolabel,
    art_nh_nordic_ecolabel,
    art_nh_fsc,
    art_nh_sonstiges,
    art_nh_sonstiges_name,
    art_nh_bitmap,

    art_pauschalartikel,
    art_stueckliste_kit,
    art_divers_flag,
    art_sammelartikel,
    art_seriennummern,
    art_charge,
    art_waschbare_krankenunterlage,
    art_wv_bettschutz,
    art_homecare_sortiment,

    art_gesperrter_artikel,
    art_auswahl_gesperrt,

    art_bilddateiname,
    art_dateiname_langtexte,
    art_katalogseite_haupt,
    art_katalogseite_medizin,
    art_pflege_partner,

    art_erfasst_von,
    art_created_at,
    art_geaendert_von,
    art_updated_at,
    source_hash

FROM {{ source('raw', 'wencke_lv_artikel_attribute') }}