{% macro golden_value_wencke(field) %}

(
    SELECT value
    FROM (
        SELECT
            s.{{ field }}::text AS value,
            COUNT(*) AS score
        FROM {{ ref('silver_wencke_artikel') }} s
        WHERE s.art_artikelnummer = base.art_artikelnummer
          AND s.{{ field }} IS NOT NULL
        GROUP BY s.{{ field }}::text
    ) x
    ORDER BY
        score DESC,
        LENGTH(value) DESC,
        value ASC
    LIMIT 1
)

{% endmacro %}