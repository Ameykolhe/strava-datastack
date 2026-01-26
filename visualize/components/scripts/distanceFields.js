export const getDistanceFields = (distanceUnit) => {
  const isKm = distanceUnit === 'km';
  return {
    distanceUnitLabel: isKm ? 'km' : 'mi',
    distanceTotalField: isKm ? 'total_distance_km' : 'total_distance_miles',
    distanceMonthlyField: isKm ? 'total_distance_km' : 'total_distance_miles',
    distanceSeriesField: isKm ? 'total_distance_km' : 'total_distance_miles',
    distanceSeriesName: isKm ? 'Distance (km)' : 'Distance (mi)',
    distanceTotalTitle: isKm ? 'Total Distance (km)' : 'Total Distance (mi)',
    distanceMonthlyTitle: isKm ? 'Distance (km)' : 'Distance (mi)'
  };
};
