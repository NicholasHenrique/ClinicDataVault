-- Grain: one row per feedback submission.
{{ config(materialized='table') }}

select
    feedback_id,
    feedback_hk,
    appointment_hk,
    patient_hk,
    rating,
    comments,
    cast(date_format(submitted_at, 'yyyyMMdd') as int) as submitted_date_key
from {{ ref('stg_patient_feedback') }}
