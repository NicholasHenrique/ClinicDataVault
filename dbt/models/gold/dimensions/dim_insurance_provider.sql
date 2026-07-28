{{ config(materialized='table') }}

select
    insurance_provider_hk,
    insurance_provider_id,
    name,
    ans_registration_number
from {{ ref('stg_insurance_providers') }}
