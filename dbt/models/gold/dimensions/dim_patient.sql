-- Unlike the other dimensions, this can no longer read staging directly:
-- a patient known to both sources now has two sat_patient rows (one per
-- record_source), and a partner-only patient has none in stg_patients at
-- all. Survivorship rule: prefer our own clinic's record when both exist,
-- otherwise use whichever is available — a simple, explicit MDM rule.
{{ config(materialized='table') }}

with ranked as (
    select
        *,
        row_number() over (
            partition by patient_hk
            order by
                case when record_source = 'clinic_generator' then 0 else 1 end,
                load_date desc
        ) as rn
    from {{ ref('sat_patient') }}
)

select
    h.patient_hk,
    r.name,
    r.cpf,
    r.birth_date,
    r.sex,
    r.phone,
    r.email,
    r.address,
    r.city,
    r.state,
    r.record_source as golden_record_source
from {{ ref('hub_patient') }} h
inner join ranked r on r.patient_hk = h.patient_hk and r.rn = 1
