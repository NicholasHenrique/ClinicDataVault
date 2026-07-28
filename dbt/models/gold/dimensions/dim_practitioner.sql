{{ config(materialized='table') }}

select
    practitioner_hk,
    practitioner_id,
    name,
    license_number,
    specialty_id,
    facility_id,
    phone,
    email
from {{ ref('stg_practitioners') }}
