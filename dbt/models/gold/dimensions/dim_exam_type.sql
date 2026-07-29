{{ config(materialized='table') }}

select
    exam_type_hk,
    exam_type_id,
    tuss_code,
    name,
    category,
    self_pay_price
from {{ ref('stg_exam_types') }}
