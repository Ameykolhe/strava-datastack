import { getDistanceFields } from './distanceFields.js';

export const getActivitySportState = ({
  distanceUnit,
  params,
  q_activity_sport__kpis,
  q_activity_sport__activities
}) => {
  const distanceFields = getDistanceFields(distanceUnit);
  const sportTitle = q_activity_sport__kpis?.[0]?.sport_type ?? params.sport;
  const distanceSupported = q_activity_sport__kpis?.length > 0 && q_activity_sport__kpis[0].total_distance_km > 0;
  const elevationSupported = q_activity_sport__kpis?.length > 0 && q_activity_sport__kpis[0].total_elevation_gain_feet > 0;
  const hasPace = q_activity_sport__activities?.length > 0 && q_activity_sport__activities[0].pace_min_per_km != null;
  const hasHeartRate = q_activity_sport__activities?.length > 0 && q_activity_sport__activities[0].average_heartrate_bpm != null;
  const hasWatts = q_activity_sport__activities?.length > 0 && q_activity_sport__activities[0].average_watts != null;
  const hasSpeed = q_activity_sport__activities?.length > 0 && q_activity_sport__activities[0].average_speed_kph != null;
  const activitiesDisplay = q_activity_sport__activities?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.distance_km : row.distance_miles
  })) ?? [];

  return {
    ...distanceFields,
    sportTitle,
    distanceSupported,
    elevationSupported,
    hasPace,
    hasHeartRate,
    hasWatts,
    hasSpeed,
    activitiesDisplay
  };
};
