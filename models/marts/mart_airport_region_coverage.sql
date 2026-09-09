{{ config(materialized='table') }}

with airports as (

    select
        coalesce(region_code, 'UNKNOWN') as region_code,
        airport_type,
        scheduled_service
    from {{ ref('dim_airport_current') }}

),

region_airports as (

    select
        case
            when split_part(region_code, '-', 1) is null
                or split_part(region_code, '-', 1) = ''
            then 'UNKNOWN'
            else split_part(region_code, '-', 1)
        end as country_code,

        case
            when split_part(region_code, '-', 2) is null
                or split_part(region_code, '-', 2) = ''
            then 'UNKNOWN'
            else split_part(region_code, '-', 2)
        end as region_code,

        airport_type,
        scheduled_service

    from airports

),

region_count as (

    select
        country_code,
        region_code,
        airport_type,
        scheduled_service,
        count(*) as total_airports
    from region_airports
    group by
        country_code,
        region_code,
        airport_type,
        scheduled_service

)

select *
from region_count