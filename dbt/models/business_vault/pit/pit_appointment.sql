-- Point-in-time table: for every appointment and a daily snapshot spine
-- (last 180 days), resolves which status was in effect on that date.
-- Exists purely for query performance: without it, every report asking
-- "what was the status as of date X" would repeat this as-of join itself.
{{ config(materialized='table') }}

with snapshot_dates as (
    select explode(sequence(date_sub(current_date(), 180), current_date(), interval 1 day)) as snapshot_date
),

appointments as (
    select appointment_hk
    from {{ ref('hub_appointment') }}
),

spine as (
    select a.appointment_hk, d.snapshot_date
    from appointments a
    cross join snapshot_dates d
),

status_history as (
    select appointment_hk, status, status_at
    from {{ ref('stg_appointment_status_history') }}
),

status_as_of as (
    select
        spine.appointment_hk,
        spine.snapshot_date,
        status_history.status,
        status_history.status_at,
        row_number() over (
            partition by spine.appointment_hk, spine.snapshot_date
            order by status_history.status_at desc
        ) as rn
    from spine
    inner join status_history
        on status_history.appointment_hk = spine.appointment_hk
       and status_history.status_at <= spine.snapshot_date
)

select
    appointment_hk,
    snapshot_date,
    status as status_as_of,
    status_at as sat_appointment_status_ldts
from status_as_of
where rn = 1
