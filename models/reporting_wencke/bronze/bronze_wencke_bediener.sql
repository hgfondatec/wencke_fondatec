{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT

        36          AS mandant,
        bed_60_3    AS bed_id,
        bed_243_10  AS erfasst_am,
        bed_261_10  AS geaendert_am,
        bed_271_5   AS geaendert_um,
        bed_1040_30 AS bed_name,
        bed_1300_1  AS warenwirtschaft,
        bed_1301_1  AS verkaufsfoerderung,
        bed_1302_1  AS kasse,
        bed_1303_1  AS finanzbuchhaltung,
        bed_1304_1  AS personalabrechnung,
        bed_1305_1  AS personalmanagement,
        bed_1306_1  AS officeplaner,
        bed_1307_1  AS anlagenbuchhaltung,
        bed_1308_1  AS kostenrechnung,
        bed_1910_3  AS v51_filialnummer,
        bed_4008_1  AS stue_preise_loeschen,
        bed_4009_1  AS stue_preise_aendern,
        bed_4010_4  AS unterzeichner_zusatz,
        bed_4014_1  AS darf_belegsperre_aendern,
        bed_4015_60 AS email_belege,
        bed_4075_20 AS fax,
        bed_4095_1  AS darf_provisionsdaten_erfassen_abrufen,
        bed_4096_1  AS reklamation_grund_sonstige,
        bed_4097_1  AS darf_bonus_erfassen_abrufen,
        bed_4098_1  AS darf_stue_abrufen_korrigieren,
        bed_4099_1  AS darf_artikel_umsetzen,
        bed_4100_1  AS ls_fiktiv_in_re_fiktiv,
        bed_4101_1  AS keine_pim_uebernahme,
        bed_4102_1  AS keine_art_massenkalkulation,
        bed_4103_1  AS keine_einzelkalkulation,
        bed_4104_1  AS rw_nicht_anzeigen,
        bed_4105_1  AS bwstatistik_admfrei,
        bed_4106_1  AS bwstatistik_export,
        bed_4107_1  AS bwstatistik_gesamt,
        bed_4108_1  AS darf_adm_umbuchen,
        bed_4109_1  AS preise_in_pos_anzeige_ausblenden,
        bed_4110_1  AS stuetzung_in_preissatz_aenderbar,
        bed_4111_1  AS bwstatistik_filiale,
        bed_4112_1  AS ek_verbergen,
        bed_4113_1  AS ek_nicht_aenderbar,
        bed_4114_1  AS darf_lieferadresse_loeschen,
        bed_4115_1  AS bwstatistik_keintabdruck,
        bed_4116_1  AS bwstatistik_admbonus,
        bed_4117_1  AS darf_rekla_auswerten,
        bed_4118_1  AS pw_aendern,
        bed_4119_1  AS druckernr_gls_etikettendruck,
        bed_4120_1  AS darf_mein_praesident_aendern,
        bed_4121_1  AS nachdruck_ls_erlaubt,
        bed_4122_1  AS inoxision_archivdruck,
        bed_4153_1  AS darf_belege_loeschen_gz0617,
        bed_4154_1  AS bwstatistik_exportwe,
        bed_4155_1  AS darf_sortiment_ueber_beleg_aendern,
        bed_4156_1  AS lfa_umsetzung_ml_markieren,
        bed_4157_1  AS lfa_umsetzung_markierung_freigeben,
        bed_4158_1  AS zf_nicht_div_art_tauschen,
        bed_4159_1  AS ek_in_div_artikelerfassung_nicht_aenderbar,
        bed_4160_1  AS darf_beleg_kostenstelle_aendern,
        bed_4161_1  AS darf_wfl_gz0540_tourdaten_aendern,
        bed_4162_30 AS mailkonto,
        bed_4192_1  AS darf_hintergrund_db_sehen,
        bed_4193_1  AS vk_fiktiv_im_preisblatt_anzeigen,
        bed_4194_1  AS darf_ptv_tourenplanungsdaten_erfassen,
        bed_4195_1  AS darf_praesidentenumleitung_erfassen,
        bed_4196_1  AS lfa_om_daten_eigene_uebernehmen,
        bed_4197_1  AS lfa_besteuerung_komplett_einstellbar,
        bed_4198_1  AS vk5_unterschreitung_in_angebot_erlauben,
        bed_4199_1  AS user_darf_mindestroh_unterschreiten,
        bed_4200_1  AS adm_sbs_statistik_innendienstansicht,
        bed_4261_1  AS darf_nachfolger_problematik_loeschen

    FROM {{ source('raw', 'm36bediener') }}


)

SELECT *
FROM bediener