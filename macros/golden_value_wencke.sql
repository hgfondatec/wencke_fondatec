{% macro golden_value_wencke(field) %}

(
    SELECT value
    FROM (
        SELECT
            NULLIF(TRIM(s.{{ field }}::text), '') AS value,
            COUNT(*) AS score
        FROM {{ ref('silver_wencke_artikel') }} s
        WHERE s.art_artikelnummer = base.art_artikelnummer
          AND NULLIF(TRIM(s.{{ field }}::text), '') IS NOT NULL
        GROUP BY
            NULLIF(TRIM(s.{{ field }}::text), '')
    ) x
    ORDER BY
        score DESC,
        LENGTH(REGEXP_REPLACE(value, '\s+', '', 'g')) DESC,
        value ASC
    LIMIT 1
)

{% endmacro %}