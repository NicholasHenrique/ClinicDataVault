{{ config(materialized='view') }}

select *
from {{ ref('stg_appointments') }}
where insurance_provider_hk is not null
