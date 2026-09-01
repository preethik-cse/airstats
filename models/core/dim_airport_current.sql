{{ config(materialized='table') }}
with current_airports as (
    Select * 
    from {{ ref('snap_airports_history') }}
    WHERE DBT_VALID_TO IS NOT NULL
)

Select 
 airport_id,
    airport_code,
    airport_name,
    airport_type,
    scheduled_service,
    country_code,
    region_code,
    municipality,
    latitude_in_degree,
    longitude_in_degree,
    elevation_ft,
    gps_code,
    iata_code,
    icao_code,
    local_code,
    continent,
    keywords,
    home_link,
    wikipedia_link,

    dbt_scd_id as airport_version_id,
    dbt_valid_from as airport_record_valid_from

from current_airports