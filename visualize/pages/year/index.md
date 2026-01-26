---
title: Year in Sports
---

```sql q_year_index__distinct_years
select
    activity_year,
    max_year
from strava.src_strava__distinct_years
order by activity_year desc
```

{#each q_year_index__distinct_years as y}

[{y.activity_year}](/year/{y.activity_year})

{/each}

[Back to Home](/)
