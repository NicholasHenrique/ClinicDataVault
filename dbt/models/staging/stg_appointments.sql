-- appointment_hk uses an "APPOINTMENT-" prefix (matched by stg_payments.reference_hk)
-- because payments reference appointments and exams through the same numeric id
-- space (reference_type + reference_id) — without the prefix, appointment #5 and
-- exam #5 would hash to the same key.
--
-- patient_hk/practitioner_hk/facility_hk/insurance_provider_hk are looked up
-- from their own staging models instead of hashed here directly, because
-- their real business keys (cpf, license_number, cnes_code,
-- ans_registration_number) don't live on this table — only the internal
-- ids do. Link hash keys are then built from these (already-correct) hub
-- hash keys rather than re-deriving from raw ids a second time — a
-- pragmatic simplification: strict Data Vault theory hashes links from raw
-- business keys too, but a link isn't meant to be independently
-- re-derived across sources the way a hub is, so hashing a hash is an
-- acceptable tradeoff here.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/appointments/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
),

patients as (
    select patient_id, patient_hk from {{ ref('stg_patients') }}
),

practitioners as (
    select practitioner_id, practitioner_hk from {{ ref('stg_practitioners') }}
),

facilities as (
    select facility_id, facility_hk from {{ ref('stg_facilities') }}
),

insurance_providers as (
    select insurance_provider_id, insurance_provider_hk from {{ ref('stg_insurance_providers') }}
),

computed as (
    select
        cast(s.appointment_id as bigint)                                                       as appointment_id,
        cast(s.rescheduled_from_id as bigint)                                                   as rescheduled_from_id,
        cast(s.patient_id as bigint)                                                            as patient_id,
        cast(s.practitioner_id as bigint)                                                       as practitioner_id,
        cast(s.specialty_id as bigint)                                                          as specialty_id,
        cast(s.facility_id as bigint)                                                           as facility_id,
        cast(s.scheduled_at as timestamp)                                                       as scheduled_at,
        s.visit_type,
        cast(s.insurance_provider_id as bigint)                                                 as insurance_provider_id,
        s.current_status,
        cast(s.created_at as timestamp)                                                         as created_at,
        sha2(upper(trim(concat('APPOINTMENT-', cast(s.appointment_id as string)))), 256)         as appointment_hk,
        case when s.rescheduled_from_id is null then null
             else sha2(upper(trim(concat('APPOINTMENT-', cast(s.rescheduled_from_id as string)))), 256)
        end                                                                                      as rescheduled_from_hk,
        p.patient_hk,
        pr.practitioner_hk,
        sha2(upper(trim(cast(s.specialty_id as string))), 256)                                   as specialty_hk,
        f.facility_hk,
        ip.insurance_provider_hk
    from source s
    inner join patients p on p.patient_id = s.patient_id
    inner join practitioners pr on pr.practitioner_id = s.practitioner_id
    inner join facilities f on f.facility_id = s.facility_id
    left join insurance_providers ip on ip.insurance_provider_id = s.insurance_provider_id
)

select
    appointment_id,
    rescheduled_from_id,
    patient_id,
    practitioner_id,
    specialty_id,
    facility_id,
    scheduled_at,
    visit_type,
    insurance_provider_id,
    current_status,
    created_at,
    appointment_hk,
    rescheduled_from_hk,
    patient_hk,
    practitioner_hk,
    specialty_hk,
    facility_hk,
    insurance_provider_hk,
    sha2(concat_ws('-', appointment_hk, patient_hk, practitioner_hk, facility_hk, specialty_hk), 256) as lnk_appointment_hk,
    case when insurance_provider_hk is null then null
         else sha2(concat_ws('-', appointment_hk, insurance_provider_hk), 256)
    end                                                                                              as lnk_appointment_insurance_hk,
    case when rescheduled_from_hk is null then null
         else sha2(concat_ws('-', appointment_hk, rescheduled_from_hk), 256)
    end                                                                                              as lnk_appointment_reschedule_hk,
    sha2(concat_ws('||',
        coalesce(cast(scheduled_at as string), ''), coalesce(cast(created_at as string), '')
    ), 256)                                                                                           as hd_appointment_detail,
    current_timestamp()                                                                              as load_date,
    'clinic_generator'                                                                               as record_source
from computed
