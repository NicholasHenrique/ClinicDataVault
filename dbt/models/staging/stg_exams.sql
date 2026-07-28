-- exam_hk uses an "EXAM-" prefix for the same reason appointment_hk uses
-- "APPOINTMENT-" — see stg_appointments.sql.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/exams/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(exam_id as bigint)                                                            as exam_id,
    cast(source_appointment_id as bigint)                                              as source_appointment_id,
    cast(patient_id as bigint)                                                         as patient_id,
    cast(exam_type_id as bigint)                                                       as exam_type_id,
    cast(facility_id as bigint)                                                        as facility_id,
    cast(scheduled_at as timestamp)                                                    as scheduled_at,
    visit_type,
    cast(insurance_provider_id as bigint)                                              as insurance_provider_id,
    current_status,
    cast(created_at as timestamp)                                                      as created_at,
    sha2(upper(trim(concat('EXAM-', cast(exam_id as string)))), 256)                    as exam_hk,
    sha2(upper(trim(concat('APPOINTMENT-', cast(source_appointment_id as string)))), 256) as source_appointment_hk,
    sha2(upper(trim(cast(patient_id as string))), 256)                                  as patient_hk,
    sha2(upper(trim(cast(exam_type_id as string))), 256)                                as exam_type_hk,
    sha2(upper(trim(cast(facility_id as string))), 256)                                 as facility_hk,
    case when insurance_provider_id is null then null
         else sha2(upper(trim(cast(insurance_provider_id as string))), 256)
    end                                                                                 as insurance_provider_hk,
    -- link hash keys: hashed from business keys, not from the hubs' own hash keys
    sha2(upper(trim(concat_ws('-',
        cast(exam_id as string), cast(patient_id as string),
        cast(exam_type_id as string), cast(facility_id as string),
        cast(source_appointment_id as string)
    ))), 256)                                                                            as lnk_exam_hk,
    case when insurance_provider_id is null then null
         else sha2(upper(trim(concat_ws('-', cast(exam_id as string), cast(insurance_provider_id as string)))), 256)
    end                                                                                 as lnk_exam_insurance_hk,
    sha2(concat_ws('||',
        coalesce(cast(scheduled_at as string), ''), coalesce(cast(created_at as string), '')
    ), 256)                                                                              as hd_exam_detail,
    current_timestamp()                                                                 as load_date,
    'clinic_generator'                                                                  as record_source
from source
