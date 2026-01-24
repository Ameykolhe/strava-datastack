---
title: Year in Sports
---

```sql distinct_years
select
    activity_year,
    max_year
from strava.distinct_years
order by activity_year desc
```

## Navigate

{#each distinct_years as y}

[{y.activity_year}](/year/{y.activity_year})

{/each}

[Back to Home](/)
