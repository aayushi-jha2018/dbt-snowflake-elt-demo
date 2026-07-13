with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        lower(trim(email)) as email,
        signup_date,
        country
    from source
)

select * from renamed
