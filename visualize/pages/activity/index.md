---
title: Activities
---

```sql sport_summary
select
    sport_type,
    lower(sport_type) as sport_slug,
    count(*) as activity_count,
    round(sum(moving_seconds) / 3600.0, 1) as total_hours,
    round(sum(distance) / 1000.0, 0) as total_km
from strava.activity_list
group by sport_type
order by activity_count desc
```

# All Activities

## By Sport Type

{#each sport_summary as sport}

### [{sport.sport_type}](/activity/{sport.sport_slug})

**{sport.activity_count}** activities | **{sport.total_hours}** hours | **{sport.total_km}** km

{/each}
