{{ config(materialized='table') }}

select
    facility_hk,
    facility_id,
    cnes_code,
    name,
    address,
    city,
    state,
    phone
from {{ ref('stg_facilities') }}
