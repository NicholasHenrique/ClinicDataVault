-- exam_hk uses an "EXAM-" prefix for the same reason appointment_hk uses
-- "APPOINTMENT-" — see stg_appointments.sql.
--
-- patient_hk/exam_type_hk/facility_hk/insurance_provider_hk are looked up
-- from their own staging models instead of hashed here directly — see the
-- header comment in stg_appointments.sql for why.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/exams/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
),

patients as (
    select patient_id, patient_hk from {{ ref('stg_patients') }}
),

exam_types as (
    select exam_type_id, exam_type_hk from {{ ref('stg_exam_types') }}
),

facilities as (
    select facility_id, facility_hk from {{ ref('stg_facilities') }}
),

insurance_providers as (
    select insurance_provider_id, insurance_provider_hk from {{ ref('stg_insurance_providers') }}
),

computed as (
    select
        cast(s.exam_id as bigint)                                                            as exam_id,
        cast(s.source_appointment_id as bigint)                                              as source_appointment_id,
        cast(s.patient_id as bigint)                                                         as patient_id,
        cast(s.exam_type_id as bigint)                                                       as exam_type_id,
        cast(s.facility_id as bigint)                                                        as facility_id,
        cast(s.scheduled_at as timestamp)                                                    as scheduled_at,
        s.visit_type,
        cast(s.insurance_provider_id as bigint)                                              as insurance_provider_id,
        s.current_status,
        cast(s.created_at as timestamp)                                                      as created_at,
        sha2(upper(trim(concat('EXAM-', cast(s.exam_id as string)))), 256)                    as exam_hk,
        sha2(upper(trim(concat('APPOINTMENT-', cast(s.source_appointment_id as string)))), 256) as source_appointment_hk,
        p.patient_hk,
        et.exam_type_hk,
        f.facility_hk,
        ip.insurance_provider_hk
    from source s
    inner join patients p on p.patient_id = s.patient_id
    inner join exam_types et on et.exam_type_id = s.exam_type_id
    inner join facilities f on f.facility_id = s.facility_id
    left join insurance_providers ip on ip.insurance_provider_id = s.insurance_provider_id
)

select
    exam_id,
    source_appointment_id,
    patient_id,
    exam_type_id,
    facility_id,
    scheduled_at,
    visit_type,
    insurance_provider_id,
    current_status,
    created_at,
    exam_hk,
    source_appointment_hk,
    patient_hk,
    exam_type_hk,
    facility_hk,
    insurance_provider_hk,
    sha2(concat_ws('-', exam_hk, patient_hk, exam_type_hk, facility_hk, source_appointment_hk), 256) as lnk_exam_hk,
    case when insurance_provider_hk is null then null
         else sha2(concat_ws('-', exam_hk, insurance_provider_hk), 256)
    end                                                                                             as lnk_exam_insurance_hk,
    sha2(concat_ws('||',
        coalesce(cast(scheduled_at as string), ''), coalesce(cast(created_at as string), '')
    ), 256)                                                                                          as hd_exam_detail,
    current_timestamp()                                                                             as load_date,
    'clinic_generator'                                                                              as record_source
from computed
