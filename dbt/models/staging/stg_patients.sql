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
    sha2(upper(trim(cast(patient_id as string))), 256)         as patient_hk,
    current_timestamp()                                        as load_date,
    'clinic_generator'                                         as record_source
from source
