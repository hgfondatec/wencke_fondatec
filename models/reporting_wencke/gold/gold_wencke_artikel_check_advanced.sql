{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'artikel_check', 'artikelvergleich', 'powerbi']
    )
}}

-- Neues dbt-Modell: gold_wencke_artikelvergleich_kategorien.sql
-- QUELLE: bestehendes dbt-Modell, das in Power BI als Dim_Artikel_Check geladen wird.
-- ACHTUNG: Falls dein tatsächlicher Modell-Dateiname anders heißt,
--          unten einmal den ref('gold_wencke_artikel_check') anpassen.
--
-- 36 Zeilen je Artikel (eine je Kategorie), vier Mandantenspalten,
-- Match, numerischer Matchscore und vier vorberechnete Hintergrundfarben.
-- Der bestehende Artikel-Check bleibt unangetastet.

{% set kategorien = [
    ('Ohne Temp.grenze?', 'art_artikel_ohne_temperaturgrenze', none, 'art_artikel_ohne_temperaturgrenze_matchscore'),
    ('Verfügbar?', 'verfuegbar', none, none),
    ('Gesperrt?', 'gesperrt', none, none),
    ('Artikelname', 'art_artikelname', 'art_artikelname_match', 'art_artikelname_matchscore'),
    ('Artikelbez. 2', 'art_bezeichnung_2', 'art_bezeichnung_2_match', 'art_bezeichnung_2_matchscore'),
    ('Artikelbez. 3', 'art_bezeichnung_3', 'art_bezeichnung_3_match', 'art_bezeichnung_3_matchscore'),
    ('Artikelbez.', 'art_bezeichnung', 'art_bezeichnung_match', 'art_bezeichnung_matchscore'),
    ('Artikelbez. 4', 'art_bezeichnung_4', 'art_bezeichnung_4_match', 'art_bezeichnung_4_matchscore'),
    ('Artikelbez. Gesamt', 'art_bezeichnung_gesamt', 'art_bezeichnung_gesamt_match', 'art_bezeichnung_gesamt_matchscore'),
    ('Hauptkategorie-Bez.', 'art_hauptkategorie_bezeichnung', 'art_hauptkategorie_bezeichnung_match', 'art_hauptkategorie_bezeichnung_matchscore'),
    ('Hauptkategorie', 'art_hauptkategorie', 'art_hauptkategorie_match', 'art_hauptkategorie_matchscore'),
    ('Hauptkategorie-Nr.', 'art_hauptkategorie_nummer', 'art_hauptkategorie_nummer_match', 'art_hauptkategorie_nummer_matchscore'),
    ('Herstellernr.', 'art_herstellernummer', 'art_herstellernummer_match', 'art_herstellernummer_matchscore'),
    ('Lagereinheit', 'art_lagereinheit', 'art_lagereinheit_match', 'art_lagereinheit_matchscore'),
    ('Lagertemp. bis', 'art_lagertemperatur_bis', 'art_lagertemperatur_bis_match', 'art_lagertemperatur_bis_matchscore'),
    ('Lagertemp. von', 'art_lagertemperatur_von', 'art_lagertemperatur_von_match', 'art_lagertemperatur_von_matchscore'),
    ('Lieferant', 'art_lieferant', 'art_lieferant_match', 'art_lieferant_matchscore'),
    ('Lieferantbez.', 'art_lieferantbezeichnung', 'art_lieferantbezeichnung_match', 'art_lieferantbezeichnung_matchscore'),
    ('Nebenkategorie', 'art_nebenkategorie', 'art_nebenkategorie_match', 'art_nebenkategorie_matchscore'),
    ('Nebenkategorie-Nr.', 'art_nebenkategorie_nummer', 'art_nebenkategorie_nummer_match', 'art_nebenkategorie_nummer_matchscore'),
    ('Nebenkategorie-Bez.', 'art_nebenkategorie_bezeichnung', 'art_nebenkategorie_bezeichnung_match', 'art_nebenkategorie_bezeichnung_matchscore'),
    ('Temp.grenze?', 'art_temperaturgrenze_vorhanden', 'art_temperaturgrenze_vorhanden_match', 'art_temperaturgrenze_vorhanden_matchscore'),
    ('Transporttemp. bis', 'art_transporttemperatur_bis', 'art_transporttemperatur_bis_match', 'art_transporttemperatur_bis_matchscore'),
    ('Transporttemp. von', 'art_transporttemperatur_von', 'art_transporttemperatur_von_match', 'art_transporttemperatur_von_matchscore'),
    ('EK. netto', 'art_ek_netto', 'art_ek_netto_match', 'art_ek_netto_matchscore'),
    ('VK 1', 'art_vk_1', 'art_vk_1_match', 'art_vk_1_matchscore'),
    ('VK 2', 'art_vk_2', 'art_vk_2_match', 'art_vk_2_matchscore'),
    ('VK 3', 'art_vk_3', 'art_vk_3_match', 'art_vk_3_matchscore'),
    ('Gesperrter Artikel', 'art_gesperrter_artikel', 'art_gesperrter_artikel_match', 'art_gesperrter_artikel_matchscore'),
    ('Nachhaltiger Artikel', 'art_nachhaltiger_artikel', 'art_nachhaltiger_artikel_match', 'art_nachhaltiger_artikel_matchscore'),
    ('Blauer Engel', 'art_nh_blauer_engel', 'art_nh_blauer_engel_match', 'art_nh_blauer_engel_matchscore'),
    ('EU Ecolabel', 'art_nh_eu_ecolabel', 'art_nh_eu_ecolabel_match', 'art_nh_eu_ecolabel_matchscore'),
    ('Nordic Ecolabel', 'art_nh_nordic_ecolabel', 'art_nh_nordic_ecolabel_match', 'art_nh_nordic_ecolabel_matchscore'),
    ('FSC', 'art_nh_fsc', 'art_nh_fsc_match', 'art_nh_fsc_matchscore'),
    ('Sonstiges Nachhaltigkeit', 'art_nh_sonstiges', 'art_nh_sonstiges_match', 'art_nh_sonstiges_matchscore'),
    ('Sonstiges Nachhaltigkeit Bez.', 'art_nh_sonstiges_name', 'art_nh_sonstiges_name_match', 'art_nh_sonstiges_name_matchscore')
] %}

WITH normalisiert AS (
    SELECT
        a.art_artikelnummer AS artikelnummer,
        a.hat_bestand,

        -- Hilfsfelder nur zur Farbberechnung; nicht in der Zieltabelle ausgegeben
        a.verfuegbar_32,
        a.verfuegbar_36,
        a.verfuegbar_39,
        a.verfuegbar_42,
        a.gesperrt_32,
        a.gesperrt_36,
        a.gesperrt_39,
        a.gesperrt_42,

        kv.kategorie_sort,
        kv.kategorie,
        kv.lloyd,
        kv.nonne,
        kv.glasofix,
        kv.vms,
        kv.match_text,
        kv.matchscore

    FROM {{ ref('gold_wencke_artikel_check') }} a

    -- PostgreSQL-Äquivalent zum DAX CROSSJOIN + SWITCH.
    -- Die Werte werden bei der dbt-Materialisierung einmal berechnet.
    CROSS JOIN LATERAL (
        VALUES
        {% for label, feld, match_feld, score_feld in kategorien %}
        (
            {{ loop.index }},
            '{{ label }}'::text,
            a.{{ feld }}_32::text,
            a.{{ feld }}_36::text,
            a.{{ feld }}_39::text,
            a.{{ feld }}_42::text,
            {% if match_feld %}a.{{ match_feld }}::text{% else %}NULL::text{% endif %},
            {% if score_feld %}a.{{ score_feld }}::integer{% else %}NULL::integer{% endif %}
        ){% if not loop.last %},{% endif %}
        {% endfor %}
    ) AS kv (
        kategorie_sort, kategorie,
        lloyd, nonne, glasofix, vms, match_text, matchscore
    )
)

SELECT
    v.artikelnummer AS "Artikelnummer",
    v.hat_bestand AS "hat_bestand",
    v.kategorie AS "Kategorie",
    v.kategorie_sort AS "Kategorie_Sort",
    v.lloyd AS "Lloyd",
    v.nonne AS "Nonne",
    v.glasofix AS "Glasofix",
    v.vms AS "VMS",
    v.match_text AS "Match",
    v.matchscore AS "Matchscore",
    -- Farbregeln werden für alle vier Mandanten identisch kompiliert
    {% for mandant_name, mandant_id, mandant_key in [
        ('Lloyd', 32, 'lloyd'),
        ('Nonne', 36, 'nonne'),
        ('Glasofix', 39, 'glasofix'),
        ('VMS', 42, 'vms')
    ] %}
    CASE
        WHEN COALESCE(v.verfuegbar_{{ mandant_id }}, 0) <> 1
            THEN '#EFB5B9'
        WHEN COALESCE(v.gesperrt_{{ mandant_id }}, 0) = 1
            THEN '#BFBFBF'
        WHEN NULLIF(BTRIM(v.match_text), '') IS NULL
            THEN NULL
        WHEN NULLIF(BTRIM(v.{{ mandant_key }}), '') IS NULL
            THEN NULL
        WHEN POSITION('///' IN v.match_text) > 0
            THEN '#DCEAF8'
        WHEN v.kategorie IN ('EK. netto', 'VK 1', 'VK 2', 'VK 3') THEN
            CASE
                -- PostgreSQL CAST nur bei gültigem Dezimalwert ausführen.
                WHEN BTRIM(v.{{ mandant_key }}) ~ '^-?[0-9]+([.,][0-9]+)?$'
                 AND BTRIM(v.match_text) ~ '^-?[0-9]+([.,][0-9]+)?$' THEN
                    CASE
                        WHEN ROUND(REPLACE(BTRIM(v.{{ mandant_key }}), ',', '.')::numeric, 2)
                           = ROUND(REPLACE(BTRIM(v.match_text), ',', '.')::numeric, 2)
                            THEN '#D8F0D8'
                        ELSE NULL
                    END
                ELSE NULL
            END
        WHEN BTRIM(v.{{ mandant_key }}) = BTRIM(v.match_text)
            THEN '#D8F0D8'
        ELSE NULL
    END AS "{{ mandant_name }}_Farbe"{% if not loop.last %},{% endif %}
    {% endfor %}

FROM normalisiert v
