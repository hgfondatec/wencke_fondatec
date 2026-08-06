{% macro golden_value(field) %}

(
    select value
    from (
        select
            value,
            count(*) as score
        from (

            select nullif(trim(t38.{{ field }}::text), '') as value
            union all
            select nullif(trim(t39.{{ field }}::text), '')
            union all
            select nullif(trim(t32.{{ field }}::text), '')
            union all
            select nullif(trim(t42.{{ field }}::text), '')
            union all
            select nullif(trim(t36.{{ field }}::text), '')

        ) s
        where value is not null
        group by value
    ) x
    order by
        score desc,
        length(regexp_replace(value, '\s+', '', 'g')) desc,
        value asc
    limit 1
)

{% endmacro %}