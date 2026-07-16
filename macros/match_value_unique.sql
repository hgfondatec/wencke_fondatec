{% macro match_value_unique(field) %}

(
    select value
    from (
        select t39.{{ field }}::text as value
        union all
        select t32.{{ field }}::text
        union all
        select t42.{{ field }}::text
        union all
        select t36.{{ field }}::text
    ) s
   where value is not null
        order by length(regexp_replace(value, '\s+', '', 'g'))
        limit 1
)

{% endmacro %}