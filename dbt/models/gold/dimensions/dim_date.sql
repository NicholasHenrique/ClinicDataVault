-- Standalone calendar dimension, independent of any hub — covers 2 years
-- back and 1 year ahead of today.
{{ config(materialized='table') }}

with days as (
    select explode(sequence(date_sub(current_date(), 730), date_add(current_date(), 365), interval 1 day)) as date_day
)

select
    cast(date_format(date_day, 'yyyyMMdd') as int) as date_key,
    date_day,
    year(date_day)                  as year,
    quarter(date_day)               as quarter,
    month(date_day)                 as month,
    date_format(date_day, 'MMMM')   as month_name,
    day(date_day)                   as day_of_month,
    dayofweek(date_day)             as day_of_week,
    date_format(date_day, 'EEEE')   as day_name,
    dayofweek(date_day) in (1, 7)   as is_weekend
from days
