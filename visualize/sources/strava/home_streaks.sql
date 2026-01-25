select
    max_activity_date,
    current_streak,
    current_streak_start_date,
    current_streak_end_date,
    longest_streak,
    active_days_last_30
from dbt_sandbox_reporting.rpt_home_streaks__all
