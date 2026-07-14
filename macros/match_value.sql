{% macro match_value(field) %}

(
    select string_agg(value, '/' order by value)
    from (
        select
            value,
            count(*) as score,
            length(value) as len
        from (
            select nullif(trim(t39.{{ field }}::text), '') as value
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
    where score = (
        select max(score)
        from (
            select
                value,
                count(*) as score
            from (
                select nullif(trim(t39.{{ field }}::text), '') as value
                union all
                select nullif(trim(t32.{{ field }}::text), '')
                union all
                select nullif(trim(t42.{{ field }}::text), '')
                union all
                select nullif(trim(t36.{{ field }}::text), '')
            ) s
            where value is not null
            group by value
        ) m
    )
)

{% endmacro %}