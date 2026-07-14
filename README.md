# dbt-snowflake-elt-demo

A small dbt project for a staging -> marts ELT pattern on Snowflake: raw seed data, cleaned staging models, an incremental fact table, and schema tests. Scaled-down version of the modelling approach used in the real-time pricing pipeline described in my portfolio.

## Run it

You need a Snowflake account (or another dbt-supported warehouse, with minor SQL tweaks) and dbt installed:

```
pip install dbt-snowflake
dbt deps
dbt seed   # load the sample CSVs as source tables
dbt run    # build staging views and mart tables
dbt test   # run schema and data tests
```

Configure the Snowflake connection in `~/.dbt/profiles.yml` under a profile named `snowflake_elt_demo` (account, user, role, warehouse, database, schema).

## The models

```
seeds/raw_customers.csv, raw_orders.csv
  -> models/staging/stg_customers.sql, stg_orders.sql   (cleaned, typed, renamed)
  -> models/marts/dim_customers.sql                      (customer dimension, enriched)
  -> models/marts/fct_orders.sql                         (incremental order facts)
```

`dim_customers.sql` enriches raw customer records with lifetime order stats computed from the fact table. `fct_orders.sql` only reprocesses new rows on later runs, using `is_incremental()` and a `unique_key`.

## CI does more than parse the project

Two jobs run on every push. `validate` installs dbt-snowflake and runs `dbt parse` against a dummy profile -- catches syntax and ref/source errors with no real credentials. `test-duckdb` installs dbt-duckdb and actually runs `dbt seed`, `dbt run`, and `dbt test` against a real, local, file-based database, which is what proves the 12 schema tests across `_staging.yml` and `_marts.yml` (not-null, uniqueness, referential integrity, accepted values) genuinely pass against materialized tables, not just that the project parses.

That second job then goes one step further: it appends a row with an invalid status value to the orders seed, re-seeds and re-runs the models, and asserts `dbt test` now fails. That's the part I actually care about -- it proves the tests catch bad data, not just that they exist in a YAML file somewhere. The seed file gets restored afterward so the repo's sample data stays clean.

## A real snag while building this

Early on, a column rename in `stg_orders.sql` didn't get propagated to `fct_orders.sql`, so `dbt run` succeeded (a missing column reference isn't a Jinja compile error) but `dbt test` failed with a confusing not-null failure on a column that, it turned out, no longer existed under that name. Chasing that down was a good reminder that dbt's compile step doesn't catch every schema mismatch -- some only show up once tests actually run against real data.

## Design notes

CI runs against dbt-duckdb rather than a real Snowflake trial account. The models and tests are written against dbt's adapter-agnostic `ref()`/`source()` abstraction and generic tests, so the same SQL runs unmodified against either backend -- Snowflake is the documented production target, DuckDB is what CI actually runs against. The trade-off is that a handful of Snowflake-specific features (clustering keys, certain semi-structured VARIANT functions) wouldn't be caught by this CI even if the project used them, since DuckDB doesn't support them. This project deliberately sticks to portable SQL to avoid that gap.

## Layout

- `dbt_project.yml`
- `seeds/raw_customers.csv`, `raw_orders.csv`
- `models/staging/_staging.yml`, `stg_customers.sql`, `stg_orders.sql`
- `models/marts/_marts.yml`, `dim_customers.sql`, `fct_orders.sql`

MIT license.
