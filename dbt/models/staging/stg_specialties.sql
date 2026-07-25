{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/specialties/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(specialty_id as bigint)                                    as specialty_id,
    name,
    sha2(upper(trim(cast(specialty_id as string))), 256)             as specialty_hk,
    current_timestamp()                                              as load_date,
    'clinic_generator'                                               as record_source
from source
