{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id, 
	adr_servicehandbuch_vorhanden,
    adr_servicehandbuch_jahr,
    adr_servicehandbuch_monat,
    adr_servicehandbuch_datum,
    adr_dosiertechnik,
    adr_serviceintervall_anzahl_jaehrlich,
    adr_schulung,
    adr_letzte_schulung_jahr,
    adr_letzte_schulung_monat,
    adr_haende_hygieneplan_vorhanden,
    adr_gefahrstoffverzeichnis

FROM {{ source('raw', 'wencke_lv_adressen_service') }}