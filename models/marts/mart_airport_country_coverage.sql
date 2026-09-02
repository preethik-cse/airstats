{{ config(materialized='table') }}
with airports as (
    select  coalesce(country_code, 'UNKNOWN') as country_code,
        airport_type,
        scheduled_service 
    from {{ ref('dim_airport_current') }}
),
country_coverage as (
    Select country_code,
    COUNT(*) AS total_airports,
    COUNT_IF(scheduled_service = 'yes') AS scheduled_service_airports,
    COUNT_IF(airport_type = 'large_airport') AS large_airports,
    COUNT_IF(airport_type = 'medium_airport') AS medium_airports,
    COUNT_IF(airport_type = 'small_airport') AS small_airports,
    COUNT_IF(airport_type = 'heliport') AS heliports,
    COUNT_IF(airport_type = 'seaplane_base') AS seaplane_bases,
    count_if(airport_type = 'balloonport') as balloonports,
    count_if(airport_type = 'closed') as closed_airports
    from airports
    group by country_code
)
select *
from country_coverage