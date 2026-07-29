-- automate_dv.hub() accepts a list of source models and unions them
-- internally, but automate_dv.sat() (in this version) only accepts a
-- single source model — so multi-source satellites need the union done
-- explicitly here first.
{{ config(materialized='view') }}

select
    name, cpf, birth_date, sex, phone, email, address, city, state,
    created_at, patient_hk, hd_patient, load_date, record_source
from {{ ref('stg_patients') }}

union all

select
    name, cpf, birth_date, sex, phone, email, address, city, state,
    created_at, patient_hk, hd_patient, load_date, record_source
from {{ ref('stg_partner_patients') }}
