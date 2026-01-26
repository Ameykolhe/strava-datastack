import { getDistanceFields } from './distanceFields.js';
import { pctChange } from '../lib/math.js';

export const getYearSportState = ({
  distanceUnit,
  params,
  q_year_sport__kpis,
  q_year_sport__activities
}) => {
  const distanceFields = getDistanceFields(distanceUnit);
  const distanceSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_distance_km > 0;
  const elevationSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_elevation_gain_feet > 0;
  const currentYear = Number(params.year);
  const currentKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear) ?? null;
  const prevKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear - 1) ?? null;
  const sportKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: distanceSupported ? pctChange(currentKpi?.[distanceFields.distanceTotalField], prevKpi?.[distanceFields.distanceTotalField]) : null,
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet) : null,
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count),
    speed_change: pctChange(currentKpi?.avg_speed_kmh, prevKpi?.avg_speed_kmh),
    pace_change: pctChange(currentKpi?.avg_pace_min_per_km, prevKpi?.avg_pace_min_per_km),
    hr_change: pctChange(currentKpi?.avg_heartrate_bpm, prevKpi?.avg_heartrate_bpm)
  } : null;
  const hasPace = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].pace_min_per_km != null;
  const hasHeartRate = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_heartrate_bpm != null;
  const hasWatts = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_watts != null;
  const hasSpeed = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_speed_kph != null;
  const activitiesDisplay = q_year_sport__activities?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.distance_km : row.distance_miles
  })) ?? [];

  return {
    ...distanceFields,
    distanceSupported,
    elevationSupported,
    sportKpisWithComparisons,
    hasPace,
    hasHeartRate,
    hasWatts,
    hasSpeed,
    activitiesDisplay
  };
};
