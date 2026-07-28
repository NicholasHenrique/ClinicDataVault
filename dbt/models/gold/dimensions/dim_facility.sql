{{ config(materialized='table') }}

select
    facility_hk,
    facility_id,
    name,
    address,
    city,
    state,
    phone
from {{ ref('stg_facilities') }}
