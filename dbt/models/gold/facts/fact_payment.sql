-- Grain: one row per payment, independent of whether it references an
-- appointment or an exam — for revenue/financial reporting that shouldn't
-- care which one it was.
{{ config(materialized='table') }}

select
    payment_id,
    payment_hk,
    reference_type,
    reference_hk,
    amount,
    payment_method,
    payment_status,
    cast(date_format(paid_at, 'yyyyMMdd') as int) as paid_date_key
from {{ ref('stg_payments') }}
