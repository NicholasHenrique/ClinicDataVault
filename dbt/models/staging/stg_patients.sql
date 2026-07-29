{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/patients/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(patient_id as bigint)                                as patient_id,
    name,
    cpf,
    cast(birth_date as date)                                  as birth_date,
    sex,
    phone,
    email,
    address,
    city,
    state,
    cast(created_at as timestamp)                             as created_at,
    -- CPF (Brazil's individual taxpayer id) is the business key, not the
    -- internal patient_id: it's the same, source-independent identifier a
    -- second system (see stg_partner_patients) would use for this same
    -- person. Digits-only normalization means formatting differences
    -- between sources ("123.456.789-01" vs "12345678901") still hash to
    -- the same key.
    sha2(upper(trim(regexp_replace(cpf, '[^0-9]', ''))), 256)  as patient_hk,
    sha2(concat_ws('||',
        coalesce(name, ''), coalesce(cpf, ''), coalesce(cast(birth_date as string), ''),
        coalesce(sex, ''), coalesce(phone, ''), coalesce(email, ''),
        coalesce(address, ''), coalesce(city, ''), coalesce(state, '')
    ), 256)                                                     as hd_patient,
    current_timestamp()                                        as load_date,
    'clinic_generator'                                         as record_source
from source
