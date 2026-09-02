select
    country_code,
    total_airports,

    large_airports
    + medium_airports
    + small_airports
    + heliports
    + seaplane_bases
    + balloonports
    + closed_airports as classified_airports

from {{ ref('mart_airport_country_coverage') }}

where total_airports != (
    large_airports
    + medium_airports
    + small_airports
    + heliports
    + seaplane_bases
    + balloonports
    + closed_airports
)