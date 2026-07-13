with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_date,
        lower(trim(status)) as status,
        order_amount
    from source
)

select * from renamed
