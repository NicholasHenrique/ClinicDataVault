-- appointment_hk uses an "APPOINTMENT-" prefix (matched by stg_payments.reference_hk)
-- because payments reference appointments and exams through the same numeric id
-- space (reference_type + reference_id) — without the prefix, appointment #5 and
-- exam #5 would hash to the same key.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/appointments/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(appointment_id as bigint)                                                         as appointment_id,
    cast(rescheduled_from_id as bigint)                                                     as rescheduled_from_id,
    cast(patient_id as bigint)                                                              as patient_id,
    cast(practitioner_id as bigint)                                                         as practitioner_id,
    cast(specialty_id as bigint)                                                            as specialty_id,
    cast(facility_id as bigint)                                                             as facility_id,
    cast(scheduled_at as timestamp)                                                         as scheduled_at,
    visit_type,
    cast(insurance_provider_id as bigint)                                                   as insurance_provider_id,
    current_status,
    cast(created_at as timestamp)                                                           as created_at,
    sha2(upper(trim(concat('APPOINTMENT-', cast(appointment_id as string)))), 256)           as appointment_hk,
    case when rescheduled_from_id is null then null
         else sha2(upper(trim(concat('APPOINTMENT-', cast(rescheduled_from_id as string)))), 256)
    end                                                                                      as rescheduled_from_hk,
    sha2(upper(trim(cast(patient_id as string))), 256)                                       as patient_hk,
    sha2(upper(trim(cast(practitioner_id as string))), 256)                                  as practitioner_hk,
    sha2(upper(trim(cast(specialty_id as string))), 256)                                     as specialty_hk,
    sha2(upper(trim(cast(facility_id as string))), 256)                                      as facility_hk,
    case when insurance_provider_id is null then null
         else sha2(upper(trim(cast(insurance_provider_id as string))), 256)
    end                                                                                      as insurance_provider_hk,
    -- link hash keys: hashed from business keys, not from the hubs' own hash keys
    sha2(upper(trim(concat_ws('-',
        cast(appointment_id as string), cast(patient_id as string),
        cast(practitioner_id as string), cast(facility_id as string),
        cast(specialty_id as string)
    ))), 256)                                                                                as lnk_appointment_hk,
    case when insurance_provider_id is null then null
         else sha2(upper(trim(concat_ws('-', cast(appointment_id as string), cast(insurance_provider_id as string)))), 256)
    end                                                                                      as lnk_appointment_insurance_hk,
    case when rescheduled_from_id is null then null
         else sha2(upper(trim(concat_ws('-', cast(appointment_id as string), cast(rescheduled_from_id as string)))), 256)
    end                                                                                      as lnk_appointment_reschedule_hk,
    current_timestamp()                                                                      as load_date,
    'clinic_generator'                                                                       as record_source
from source
