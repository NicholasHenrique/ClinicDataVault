{{ config(materialized='table') }}

select
    specialty_hk,
    specialty_id,
    name
from {{ ref('stg_specialties') }}
