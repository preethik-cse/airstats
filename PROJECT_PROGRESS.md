# Airport Analytics dbt Project — Progress

## Goal

Build a production-style airport analytics pipeline for a portfolio: reliable ingestion, tested transformations, historical tracking, orchestration, CI/CD, documentation, and observability.

## Current architecture

```text
Airport CSV
  -> Airbyte sync (every 24 hours)
  -> RAW.OUR_AIRPORTS.OURAIRPORTS_CSV
  -> DEV.DBT_PSHETTY.STG_AIRPORTS
  -> DEV.DBT_PSHETTY.SNAP_AIRPORTS_HISTORY
  -> DEV.DBT_PSHETTY.DIM_AIRPORT_CURRENT
```

Snowflake layers created so far:

- `RAW`: Airbyte-managed ingestion layer.
- `DEV`: personal dbt development database.
- `PROD`: future deployment database, with `STAGING`, `CORE`, and `MART` schemas.

## What is implemented

### Ingestion and source health

- Airbyte loads the airport CSV into Snowflake every 24 hours.
- The dbt source declaration points to `RAW.OUR_AIRPORTS.OURAIRPORTS_CSV`.
- Freshness SLA is configured to warn after 24 hours and fail after 36 hours.

### Staging: `stg_airports`

- Materialized as a view.
- Renames and explicitly casts raw airport fields.
- Deduplicates repeated Airbyte records with `row_number()`.
- Keeps the latest `_AIRBYTE_EXTRACTED_AT` record for each `airport_id`.
- Tests guarantee `airport_id` is `not_null` and `unique`.

Why: Airbyte raw data retains ingestion history. Staging provides one clean, current source-aligned record per airport without deleting audit data.

### Snapshot: `snap_airports_history`

- Uses a dbt SCD Type 2 snapshot.
- Tracks listed business-column changes using the `check` strategy.
- Uses `airport_id` as its business key.
- Invalidates a current record if it disappears from the source.

Why: the snapshot preserves previous airport versions, while staging shows only the latest source state.

### Core: `dim_airport_current`

- Materialized as a table.
- Reads the snapshot and filters to `dbt_valid_to is null`.
- Contains the current business-approved record for each airport.
- Exposes clear domain names:
  - `airport_version_id` for dbt's `dbt_scd_id`
  - `airport_record_valid_from` for dbt's `dbt_valid_from`
- Tests `airport_id` and `airport_version_id` for uniqueness and non-null values.
- Has a singular reconciliation test proving it exactly matches the snapshot's current records.

Why: a core dimension is the stable, efficient interface used by future marts and dashboards. It isolates consumers from raw-data and snapshot implementation details.

## Important data-quality lesson

The first uniqueness test failed because the raw Airbyte relation contained repeated daily airport extracts. The test exposed the issue before it reached analytics output. The staging deduplication fixed it without deleting raw records.

Another semantic issue was caught through reconciliation: filtering `dbt_valid_to is not null` selected expired records, while `is null` selects current records. Generic `not_null` and `unique` tests alone could not detect that business-logic error. This is why the singular test exists.

## Current verification result

Latest successful scoped build:

```text
dbt build --select +dim_airport_current
PASS=11, WARN=0, ERROR=0
```

It built, in dependency order:

1. `stg_airports` view
2. staging tests
3. airport history snapshot
4. `dim_airport_current` table
5. dimension generic tests
6. snapshot-to-dimension singular reconciliation test

At the latest verification, the current dimension contained 86,003 unique airports. This number can change as Airbyte receives new source data.

## Commands used

```powershell
dbt parse
dbt source freshness
dbt build
dbt build --select stg_airports
dbt build --select +dim_airport_current
dbt snapshot
dbt test

git status
git add <file>
git commit -m "<clear message>"
```

Development routine before CI/CD:

```text
Edit a small, coherent change
-> dbt parse
-> build the smallest relevant lineage
-> review Git changes
-> commit the validated change
```

Manual daily routine before orchestration:

```text
Airbyte sync completes
-> dbt source freshness
-> dbt build
-> investigate and fix any failure
```

## Next implementation steps

1. Build a business-facing mart, beginning with airport coverage by country, region, type, and scheduled-service availability.
2. Add mart documentation, tests, and business metric definitions.
3. Generate and publish dbt documentation; replace the starter README with project architecture and operating instructions.
4. Create a GitHub remote and adopt pull-request workflow.
5. Add GitHub Actions CI: parse, targeted dbt builds/tests, and linting.
6. Introduce Dagster to orchestrate Airbyte, source freshness, dbt build, alerts, and backfills.
7. Add production roles, least-privilege Snowflake grants, secret management, and environment-specific deployments.

## Materialization decisions

```text
Airbyte RAW table       -> managed by Airbyte, not by dbt
stg_airports            -> view: lightweight cleanup and deduplication
snapshot                -> table: durable SCD Type 2 history
dim_airport_current     -> table: stable, reusable analytics interface
future event fact model -> incremental only when data volume and a reliable
                           event/update watermark make full rebuilds costly
```

Do not use incremental simply because a job runs daily. Use it when data is large, changes can be identified safely, and a full rebuild is no longer economical.
