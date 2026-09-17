{% macro standardize_missing(column_name) %}
COALESCE({{ column_name }}, 'UNKNOWN')
{% endmacro %}