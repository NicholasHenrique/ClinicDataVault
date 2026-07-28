{{ config(materialized='view') }}

select *
from {{ ref('stg_payments') }}
where reference_type = 'APPOINTMENT'
