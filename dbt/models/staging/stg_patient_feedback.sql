-- Third source: an external satisfaction survey tool. It identifies the
-- patient by CPF (it serves many clinics, so it never learned our internal
-- patient_id) but does know which appointment we asked it to survey.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/patient_feedback/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(feedback_id as bigint)                                                    as feedback_id,
    cast(appointment_id as bigint)                                                 as appointment_id,
    cpf,
    cast(rating as int)                                                            as rating,
    comments,
    cast(submitted_at as timestamp)                                                as submitted_at,
    sha2(upper(trim(cast(feedback_id as string))), 256)                             as feedback_hk,
    sha2(upper(trim(concat('APPOINTMENT-', cast(appointment_id as string)))), 256)  as appointment_hk,
    sha2(upper(trim(regexp_replace(cpf, '[^0-9]', ''))), 256)                       as patient_hk,
    sha2(concat_ws('-',
        sha2(upper(trim(cast(feedback_id as string))), 256),
        sha2(upper(trim(regexp_replace(cpf, '[^0-9]', ''))), 256),
        sha2(upper(trim(concat('APPOINTMENT-', cast(appointment_id as string)))), 256)
    ), 256)                                                                          as lnk_feedback_hk,
    sha2(concat_ws('||', coalesce(cast(rating as string), ''), coalesce(comments, '')), 256) as hd_feedback,
    current_timestamp()                                                             as load_date,
    'feedback_survey'                                                              as record_source
from source
