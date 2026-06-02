WITH t1 AS (

    SELECT *
    FROM {{ ref('nonne_prep_rechnung_belege') }}
    WHERE rechnung_interne_beleg_nr <> ''

),

t2 AS (

    SELECT *
    FROM {{ ref('nonne_bronze_positionen') }}
    WHERE pos_artikeltext ILIKE '%pauschale%'
      AND pos_artikelnummer <> '' AND pos_beleg_status ='N'

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
    t2.pos_artikelnummer,
    t2.pos_positionsnummer,
    NULLIF(REPLACE(t2.pos_rohertrag_vor_bonus, ',', '.'), '')::float AS pos_rohertrag_vor_bonus,
    NULLIF(REPLACE(t2.pos_gesamtmenge, ',', '.'), '')::float AS pos_gesamtmenge,
    NULLIF(REPLACE(t2.pos_gesamtumsatz, ',', '.'), '')::float AS pos_gesamtumsatz,
    NULLIF(REPLACE(t2.pos_gesamtumsatz_vor_bonus, ',', '.'), '')::float AS pos_gesamtumsatz_vor_bonus,
    NULLIF(REPLACE(t2.pos_gesamtrohertrag, ',', '.'), '')::float AS pos_gesamtrohertrag,
    NULLIF(REPLACE(t2.pos_ek_einzeln, ',', '.'), '')::float AS pos_ek_einzeln

FROM  t1

LEFT JOIN  t2 
    ON t1.rechnung_interne_beleg_nr = t2.pos_belegnummer

LEFT JOIN {{ ref('nonne_prep_beleggruppe') }} beleggruppe 
    ON LPAD(beleggruppe.bg_beleggruppe_id::varchar, 2, '0') = t1.rechnung_beleggruppe
   AND beleggruppe.bg_belegart = t1.rechnung_belegart

WHERE t2.pos_artikeltext IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM t2 AS t2_check
      WHERE t2_check.pos_belegnummer = t1.rechnung_beleg_nr
  )