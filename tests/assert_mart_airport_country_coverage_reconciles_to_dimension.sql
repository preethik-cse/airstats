with expected_airport_total as (

    select
        count(*) as airport_count
    from {{ ref('dim_airport_current') }}

),

actual_airport_total as (

    select
        coalesce(sum(total_airports), 0) as airport_count
    from {{ ref('mart_airport_country_coverage') }}

)

select
    expected_airport_total.airport_count as expected_airport_count,
    actual_airport_total.airport_count as actual_airport_count

from expected_airport_total
cross join actual_airport_total

where expected_airport_total.airport_count != actual_airport_total.airport_count