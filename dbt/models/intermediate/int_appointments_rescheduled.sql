{{ config(materialized='view') }}

select *
from {{ ref('stg_appointments') }}
where rescheduled_from_hk is not null
