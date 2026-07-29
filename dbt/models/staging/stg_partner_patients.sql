-- Second source: a partner clinic's own patient registry. Its patient_hk
-- must be computed exactly like stg_patients' (same CPF normalization),
-- since that's what lets hub_patient/sat_patient integrate the same real
-- person from two different systems. This feed never sends
-- birth_date/sex/address, so those are nulled to line up with
-- stg_patients' column shape.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/partner_patients/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(partner_patient_id as bigint)                          as partner_patient_id,
    name,
    cpf,
    cast(null as date)                                          as birth_date,
    cast(null as string)                                        as sex,
    phone,
    email,
    cast(null as string)                                        as address,
    city,
    state,
    cast(registered_at as timestamp)                            as created_at,
    sha2(upper(trim(regexp_replace(cpf, '[^0-9]', ''))), 256)   as patient_hk,
    sha2(concat_ws('||',
        coalesce(name, ''), coalesce(cpf, ''), '',
        '', coalesce(phone, ''), coalesce(email, ''),
        '', coalesce(city, ''), coalesce(state, '')
    ), 256)                                                      as hd_patient,
    current_timestamp()                                         as load_date,
    'partner_clinic'                                            as record_source
from source
