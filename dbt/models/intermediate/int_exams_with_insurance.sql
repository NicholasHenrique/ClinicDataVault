{{ config(materialized='view') }}

select *
from {{ ref('stg_exams') }}
where insurance_provider_hk is not null
