-- specialty_id / facility_id are kept as plain attributes here (not links):
-- a practitioner has exactly one current specialty and facility, and that
-- assignment can change over time, which is exactly what a satellite tracks.
{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='practitioner_hk',
    src_hashdiff='hd_practitioner',
    src_payload=['name', 'license_number', 'specialty_id', 'facility_id', 'phone', 'email'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_practitioners'
) }}
