with source_data AS (
    Select *
    FROM {{ source('our_airports_raw', 'ourairports_csv') }}
),
staged as (

    -- 2. Clean, rename, and cast the data
    select
        -- Identifiers
        cast(id as integer) as airport_id,
        ident as airport_code,

        -- Business Dimensions
        name as airport_name,
        type as airport_type,
        scheduled_service,

        -- Location Codes (Applying your naming conventions)
        iso_country as country_code,
        iso_region as region_code,
        municipality,

        -- Coordinates & Elevation (Casting explicitly to numbers)
        cast(latitude_deg as float) as latitude_in_degree,
        cast(longitude_deg as float) as longitude_in_degree,
        cast(elevation_ft as integer) as elevation_ft,

        -- Sparse/Optional Data
        gps_code,
        iata_code,
        icao_code,
        local_code,
        continent,
        keywords,
        home_link,
        wikipedia_link

        -- Note: We completely omitted _AIRBYTE_RAW_ID, _AIRBYTE_EXTRACTED_AT, etc.

    from source_data

)

-- 3. Final selection
select * 
from staged