{% macro match_value(field) %}

(
    select value
    from (
        select
            value,
            count(*) as score,
            length(value) as len
        from (

            select nullif(trim(t39.{{ field }}), '') as value
            union all
            select nullif(trim(t32.{{ field }}), '')
            union all
            select nullif(trim(t42.{{ field }}), '')
            union all
            select nullif(trim(t36.{{ field }}), '')

        ) s
        where value is not null
        group by value
    ) x
    order by score desc, len asc
    limit 1
)

{% endmacro %}