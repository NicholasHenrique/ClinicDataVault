-- Grain: one row per appointment. current_status comes from pit_appointment
-- (today's snapshot) so the mart reflects the Business Vault's resolved
-- as-of status rather than re-deriving it here; exam/payment linkage comes
-- from bridge_encounter instead of re-joining the raw links.
{{ config(materialized='table') }}

with today_status as (
    select appointment_hk, status_as_of
    from {{ ref('pit_appointment') }}
    where snapshot_date = current_date()
),

bridge as (
    select appointment_hk, exam_hk, exam_type_hk, appointment_payment_hk
    from {{ ref('bridge_encounter') }}
),

payment as (
    select payment_hk, amount, payment_method, payment_status
    from {{ ref('stg_payments') }}
)

select
    a.appointment_id,
    a.appointment_hk,
    a.patient_hk,
    a.practitioner_hk,
    a.facility_hk,
    a.specialty_hk,
    a.insurance_provider_hk,
    b.exam_hk,
    b.exam_type_hk,
    cast(date_format(a.scheduled_at, 'yyyyMMdd') as int) as scheduled_date_key,
    a.visit_type,
    coalesce(ts.status_as_of, a.current_status)          as current_status,
    p.amount                                              as amount_paid,
    p.payment_method,
    p.payment_status,
    b.exam_hk is not null                                 as has_exam,
    1                                                      as appointment_count
from {{ ref('stg_appointments') }} a
left join today_status ts on ts.appointment_hk = a.appointment_hk
left join bridge b on b.appointment_hk = a.appointment_hk
left join payment p on p.payment_hk = b.appointment_payment_hk
