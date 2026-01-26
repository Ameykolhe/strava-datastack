import { goto } from '$app/navigation';
import { getDistanceFields } from './distanceFields.js';

const isBrowser = typeof window !== 'undefined';

export const getActivityIndexState = ({
  distanceUnit,
  q_activity__recent_activities
}) => {
  const distanceFields = getDistanceFields(distanceUnit);
  const recentActivitiesDisplay = q_activity__recent_activities?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.distance_km : row.distance_miles
  })) ?? [];

  return {
    ...distanceFields,
    recentActivitiesDisplay
  };
};

export const handleSportPieClick = (event) => {
  const payload = event?.detail ?? event;
  const slug = payload?.data?.sport_slug;
  if (slug && isBrowser) goto(`/activity/${slug}`);
};
