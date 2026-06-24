{% macro safe_float(col) %}
case
    when replace(trim({{ col }}), ',', '.') ~ '^-?[0-9]+(\.[0-9]+)?$'
        then replace(trim({{ col }}), ',', '.')::float
    else null
end
{% endmacro %}