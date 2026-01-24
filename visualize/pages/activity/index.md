---
title: Activities
---

```sql sport_summary
select
    sport_type,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    sport_slug
from strava.activities_by_sport
order by activity_count desc
```

# All Activities

## By Sport Type

{#each sport_summary as sport}

### [{sport.sport_type}](/activity/{sport.sport_slug})

**{sport.activity_count}** activities | **{sport.total_moving_time_hours}** hours | **{sport.total_distance_km}** km

{/each}
