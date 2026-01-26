import { goto } from '$app/navigation';
import { getDistanceFields } from './distanceFields.js';
import { pctChange } from '../lib/math.js';

const isBrowser = typeof window !== 'undefined';

export const getYearState = ({
  distanceUnit,
  params,
  q_year__kpis
}) => {
  const distanceFields = getDistanceFields(distanceUnit);
  const currentYear = Number(params.year);
  const currentKpi = q_year__kpis?.find((row) => row.activity_year === currentYear) ?? null;
  const prevKpi = q_year__kpis?.find((row) => row.activity_year === currentYear - 1) ?? null;
  const yearKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: pctChange(currentKpi?.[distanceFields.distanceTotalField], prevKpi?.[distanceFields.distanceTotalField]),
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet),
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count)
  } : null;

  return {
    ...distanceFields,
    yearKpisWithComparisons
  };
};

export const createYearSportPieClickHandler = (params) => (event) => {
  const payload = event?.detail ?? event;
  const slug = payload?.data?.sport_slug;
  if (slug && isBrowser) goto(`/year/${params.year}/${slug}`);
};
