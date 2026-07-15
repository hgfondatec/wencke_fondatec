WITH t1 AS (

    SELECT *
    FROM {{ ref('vms_prep_rechnung_belege') }}
    WHERE rechnung_interne_beleg_nr <> ''

),

rechnung_rezept_ref AS (

    SELECT
        pos.pos_belegnummer AS rechnung_beleg_nr,
        substring(pos.pos_artikeltext FROM 'Rezept Nr\.?\s*([0-9]+)') AS interne_rezept_nr
    FROM {{ ref('vms_bronze_positionen') }} pos
    WHERE pos.pos_artikeltext ILIKE '%Übernahme von Rezept Nr.%'
      AND pos.pos_beleg_status = 'N'

),

pauschalen AS (

    SELECT *
    FROM {{ ref('vms_bronze_positionen') }}
    WHERE pos_artikeltext ILIKE '%pauschale%'
      AND pos_artikelnummer <> ''
      AND pos_beleg_status = 'N'

)

SELECT 
    t1.rechnung_beleg_nr,
    t1.rechnung_bel_datum,
    t1.rechnung_adressnummer,
    t1.rechnung_projektnummer,
    t1.rechnung_heim,
    t1.rechnung_belegart,
    t1.rechnung_steuerart,
    t1.rechnung_bonusbelege_flag,

    beleggruppe.bg_beleggruppe,
    beleggruppe."BG_Beleggruppe",

    p.pos_artikelnummer,
    p.pos_positionsnummer,

    NULLIF(REPLACE(p.pos_rohertrag_vor_bonus, ',', '.'), '')::float AS pos_rohertrag_vor_bonus,
    NULLIF(REPLACE(p.pos_gesamtmenge, ',', '.'), '')::float AS pos_gesamtmenge,
    NULLIF(REPLACE(p.pos_gesamtumsatz, ',', '.'), '')::float AS pos_gesamtumsatz,
    NULLIF(REPLACE(p.pos_gesamtumsatz_vor_bonus, ',', '.'), '')::float AS pos_gesamtumsatz_vor_bonus,
    NULLIF(REPLACE(p.pos_gesamtrohertrag, ',', '.'), '')::float AS pos_gesamtrohertrag,
    NULLIF(REPLACE(p.pos_ek_einzeln, ',', '.'), '')::float AS pos_ek_einzeln

FROM t1

JOIN rechnung_rezept_ref r
    ON r.rechnung_beleg_nr = t1.rechnung_beleg_nr

JOIN pauschalen p
    ON p.pos_belegnummer = r.interne_rezept_nr

LEFT JOIN {{ ref('vms_prep_beleggruppe') }} beleggruppe 
    ON LPAD(beleggruppe.bg_beleggruppe_id::varchar, 2, '0') = t1.rechnung_beleggruppe
   AND beleggruppe.bg_belegart = t1.rechnung_belegart

WHERE NOT EXISTS (
    SELECT 1
    FROM pauschalen p_check
    WHERE p_check.pos_belegnummer = t1.rechnung_beleg_nr
      AND p_check.pos_artikelnummer = p.pos_artikelnummer
)