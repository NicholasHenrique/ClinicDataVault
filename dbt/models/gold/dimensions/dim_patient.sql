-- Built straight from staging (not from hub+satellite): the generator only
-- ever produces one snapshot per patient, so staging already holds exactly
-- one row per patient_hk — no "latest version" resolution is needed.
{{ config(materialized='table') }}

select
    patient_hk,
    patient_id,
    name,
    cpf,
    birth_date,
    sex,
    phone,
    email,
    address,
    city,
    state
from {{ ref('stg_patients') }}
