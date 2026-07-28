-- Bridge table: flattens the appointment's core link plus every optional
-- link that may hang off it (insurance, the exam it generated, and the
-- payment for either) into a single row. Exists purely for query
-- performance: without it, a report needs to join 5 link tables to answer
-- "what was billed for this appointment".
{{ config(materialized='table') }}

with appointment as (
    select appointment_hk, patient_hk, practitioner_hk, facility_hk, specialty_hk
    from {{ ref('lnk_appointment') }}
),

appointment_insurance as (
    select appointment_hk, insurance_provider_hk
    from {{ ref('lnk_appointment_insurance') }}
),

exam as (
    select exam_hk, source_appointment_hk, exam_type_hk
    from {{ ref('lnk_exam') }}
),

appointment_payment as (
    -- lnk_payment_appointment's reference_hk holds the same value as
    -- appointment_hk (both hashed from the "APPOINTMENT-<id>" prefix) but
    -- keeps its own column name since it's a generic reference, not an
    -- appointment-specific one — see exam_payment below for the same case.
    select reference_hk as appointment_hk, payment_hk
    from {{ ref('lnk_payment_appointment') }}
),

exam_payment as (
    -- lnk_payment_exam's reference_hk holds the same value as exam_hk
    -- (both hashed from the "EXAM-<id>" prefix) but keeps its own column
    -- name since it's a generic reference, not an exam-specific one.
    select e.source_appointment_hk as appointment_hk, e.exam_hk, p.payment_hk
    from {{ ref('lnk_payment_exam') }} p
    inner join exam e on e.exam_hk = p.reference_hk
)

select
    a.appointment_hk,
    a.patient_hk,
    a.practitioner_hk,
    a.facility_hk,
    a.specialty_hk,
    ai.insurance_provider_hk as appointment_insurance_provider_hk,
    ex.exam_hk,
    ex.exam_type_hk,
    ap.payment_hk as appointment_payment_hk,
    exp.payment_hk as exam_payment_hk
from appointment a
left join appointment_insurance ai on ai.appointment_hk = a.appointment_hk
left join exam ex on ex.source_appointment_hk = a.appointment_hk
left join appointment_payment ap on ap.appointment_hk = a.appointment_hk
left join exam_payment exp
    on exp.appointment_hk = a.appointment_hk
   and exp.exam_hk = ex.exam_hk
