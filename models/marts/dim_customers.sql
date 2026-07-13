with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_order_stats as (
    select
        customer_id,
        count(*) as lifetime_order_count,
        sum(order_amount) as lifetime_order_value,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.signup_date,
    c.country,
    coalesce(s.lifetime_order_count, 0) as lifetime_order_count,
    coalesce(s.lifetime_order_value, 0) as lifetime_order_value,
    s.first_order_date,
    s.most_recent_order_date
from customers c
left join customer_order_stats s
    on c.customer_id = s.customer_id
