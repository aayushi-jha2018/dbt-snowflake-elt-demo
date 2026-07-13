{{
    config(
        materialized='incremental',
        unique_key='order_id',
        on_schema_change='sync_all_columns'
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}

    {% if is_incremental() %}
    where order_date >= (select max(order_date) from {{ this }})
    {% endif %}
)

select
    order_id,
    customer_id,
    order_date,
    status,
    order_amount
from orders
