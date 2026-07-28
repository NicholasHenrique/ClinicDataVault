-- Grain: one row per exam. stg_exams already carries every relevant hash
-- key (patient/facility/exam_type/source_appointment/insurance_provider),
-- computed once in the staging layer.
{{ config(materialized='table') }}

with payment_link as (
    select payment_hk, reference_hk as exam_hk
    from {{ ref('lnk_payment_exam') }}
),

payment as (
    select payment_hk, amount, payment_method, payment_status
    from {{ ref('stg_payments') }}
)

select
    e.exam_id,
    e.exam_hk,
    e.source_appointment_hk as appointment_hk,
    e.patient_hk,
    e.facility_hk,
    e.exam_type_hk,
    e.insurance_provider_hk,
    cast(date_format(e.scheduled_at, 'yyyyMMdd') as int) as scheduled_date_key,
    e.visit_type,
    e.current_status,
    p.amount         as amount_paid,
    p.payment_method,
    p.payment_status,
    1                as exam_count
from {{ ref('stg_exams') }} e
left join payment_link pl on pl.exam_hk = e.exam_hk
left join payment p on p.payment_hk = pl.payment_hk
