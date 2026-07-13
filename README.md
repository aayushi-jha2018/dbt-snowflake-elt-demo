# dbt-snowflake-elt-demo

[![CI](https://github.com/aayushi-jha2018/dbt-snowflake-elt-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/aayushi-jha2018/dbt-snowflake-elt-demo/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A small dbt project demonstrating a staging -> marts ELT pattern for Snowflake: raw seed data, cleaned staging models, an incremental fact table, and schema tests. This mirrors the modelling approach used in the real-time pricing pipeline and dbt ELT work described in my [portfolio](https://github.com/aayushi-jha2018/portfolio), scaled down to a runnable example.

## Architecture

```
seeds/raw_customers.csv, seeds/raw_orders.csv (sample source data)
        |
        v
models/staging/stg_customers.sql (cleaned, typed, renamed)
models/staging/stg_orders.sql
        |
        v
models/marts/dim_customers.sql (customer dimension, enriched)
models/marts/fct_orders.sql (incremental order facts)
```

## Project structure

```
dbt-snowflake-elt-demo/
|-- dbt_project.yml
|-- seeds/
|   |-- raw_customers.csv
|   `-- raw_orders.csv
`-- models/
    |-- staging/
    |   |-- _staging.yml   # sources (with identifiers) + column tests
    |   |-- stg_customers.sql
    |   `-- stg_orders.sql
    `-- marts/
        |-- _marts.yml     # column tests
        |-- dim_customers.sql
        `-- fct_orders.sql # incremental model
```

## Running this project

You need a Snowflake account (or another dbt-supported warehouse, with minor SQL tweaks) and dbt installed:

```bash
pip install dbt-snowflake
dbt deps
dbt seed   # load the sample CSVs as source tables
dbt run    # build staging views and mart tables
dbt test   # run schema and data tests
```

Configure your Snowflake connection in `~/.dbt/profiles.yml` under a profile named `snowflake_elt_demo` (account, user, role, warehouse, database, schema).

## Continuous integration

CI runs two jobs on every push:

- **validate**: installs `dbt-snowflake` and runs `dbt parse` against a dummy Snowflake profile, to catch syntax and ref/source errors without needing real credentials.
- **test-duckdb**: installs `dbt-duckdb` and actually runs `dbt seed`, `dbt run`, and `dbt test` against a real (local, file-based) database -- no cloud account needed. This is the job that proves the 12 schema tests across `_staging.yml` and `_marts.yml` (not-null, uniqueness, referential integrity, accepted-value checks) genuinely pass against real materialized tables, not just that the project parses.

The `test-duckdb` job then goes a step further: it appends a row with an invalid `status` value to the orders seed, re-seeds and re-runs the models, and asserts that `dbt test` now **fails** -- proving the data-quality tests actually catch bad data, not just that they're present in the YAML. The seed file is restored afterward so the repo's sample data is unaffected.

## What this demonstrates

- **Staging layer**: one model per source table, renaming and typing columns without changing grain -- `models/staging/stg_customers.sql`, `models/staging/stg_orders.sql`.
- **Incremental loading**: `fct_orders.sql` only reprocesses new rows on subsequent runs, using `is_incremental()` and a `unique_key`.
- **Testing that's actually verified, not just declared**: `_staging.yml` and `_marts.yml` enforce not-null, uniqueness, referential integrity, and accepted-value constraints, and CI proves both that they pass on good data and that they fail on bad data.
- **Dimensional modelling**: `dim_customers.sql` enriches raw customer records with lifetime order stats computed from the fact table.
- **Adapter portability**: the same models and tests run unmodified against Snowflake (documented, production target) or DuckDB (CI, credential-free), since dbt's source/ref abstraction and generic tests are adapter-agnostic.

## License

MIT -- feel free to reuse this as a starting point.
