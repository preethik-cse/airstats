with expected_current_records  as (
    Select airport_id,dbt_scd_id as airport_version_id
    from {{ ref('snap_airports_history') }}
    WHERE DBT_VALID_TO IS NULL
),
dimension_records as (
    Select airport_id, airport_version_id
    from {{ ref('dim_airport_current') }}
),
missing_from_dimension as (
     select * from expected_current_records
    minus
    select * from dimension_records
),
unexpected_in_dimension as (

    select * from dimension_records
    minus
    select * from expected_current_records

)

select * from missing_from_dimension

union all

select * from unexpected_in_dimension