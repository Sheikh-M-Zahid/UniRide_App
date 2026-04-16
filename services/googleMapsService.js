const axios = require('axios');

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const GOOGLE_ROUTES_API_URL =
  process.env.GOOGLE_ROUTES_API_URL || 'https://routes.googleapis.com';
const GOOGLE_GEOCODING_API_URL =
  process.env.GOOGLE_GEOCODING_API_URL ||
  'https://maps.googleapis.com/maps/api/geocode/json';

const ensureApiKey = () => {
  if (!GOOGLE_MAPS_API_KEY) {
    throw new Error('GOOGLE_MAPS_API_KEY is missing.');
  }
};

const geocodeAddress = async (address) => {
  ensureApiKey();

  const response = await axios.get(GOOGLE_GEOCODING_API_URL, {
    params: {
      address,
      key: GOOGLE_MAPS_API_KEY,
    },
    timeout: 10000,
  });

  const data = response.data;

  if (!data.results || !data.results.length) {
    throw new Error('Address could not be geocoded.');
  }

  const first = data.results[0];

  return {
    formattedAddress: first.formatted_address,
    lat: first.geometry.location.lat,
    lng: first.geometry.location.lng,
    placeId: first.place_id,
  };
};

const reverseGeocode = async ({ lat, lng }) => {
  ensureApiKey();

  const response = await axios.get(GOOGLE_GEOCODING_API_URL, {
    params: {
      latlng: `${lat},${lng}`,
      key: GOOGLE_MAPS_API_KEY,
    },
    timeout: 10000,
  });

  const data = response.data;

  if (!data.results || !data.results.length) {
    throw new Error('Coordinates could not be reverse geocoded.');
  }

  const first = data.results[0];

  return {
    formattedAddress: first.formatted_address,
    placeId: first.place_id,
  };
};

const parseDurationSeconds = (durationString) => {
  if (!durationString) return 0;
  return Number(String(durationString).replace('s', '')) || 0;
};

const computeRoute = async ({
  originLat,
  originLng,
  destinationLat,
  destinationLng,
  travelMode = 'DRIVE',
}) => {
  ensureApiKey();

  const url = `${GOOGLE_ROUTES_API_URL}/directions/v2:computeRoutes`;

  const response = await axios.post(
    url,
    {
      origin: {
        location: {
          latLng: {
            latitude: originLat,
            longitude: originLng,
          },
        },
      },
      destination: {
        location: {
          latLng: {
            latitude: destinationLat,
            longitude: destinationLng,
          },
        },
      },
      travelMode,
      routingPreference: 'TRAFFIC_AWARE',
      computeAlternativeRoutes: false,
      languageCode: 'en',
      units: 'METRIC',
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
        'X-Goog-FieldMask':
          'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      },
      timeout: 12000,
    }
  );

  const routes = response.data?.routes || [];

  if (!routes.length) {
    throw new Error('No route found.');
  }

  const route = routes[0];
  const distanceKm = Number((route.distanceMeters / 1000).toFixed(2));
  const durationMinutes = Math.max(
    1,
    Math.round(parseDurationSeconds(route.duration) / 60)
  );

  return {
    distanceKm,
    durationMinutes,
    polyline: route.polyline?.encodedPolyline || null,
  };
};

const computeRouteMatrix = async ({
  origin,
  destinations,
  travelMode = 'DRIVE',
}) => {
  ensureApiKey();

  if (!destinations?.length) {
    return [];
  }

  const url = `${GOOGLE_ROUTES_API_URL}/distanceMatrix/v2:computeRouteMatrix`;

  const response = await axios.post(
    url,
    {
      origins: [
        {
          waypoint: {
            location: {
              latLng: {
                latitude: origin.lat,
                longitude: origin.lng,
              },
            },
          },
        },
      ],
      destinations: destinations.map((d) => ({
        waypoint: {
          location: {
            latLng: {
              latitude: d.lat,
              longitude: d.lng,
            },
          },
        },
      })),
      travelMode,
      routingPreference: 'TRAFFIC_AWARE',
      languageCode: 'en',
      units: 'METRIC',
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
        'X-Goog-FieldMask':
          'originIndex,destinationIndex,distanceMeters,duration,status,condition',
      },
      timeout: 15000,
    }
  );

  const rows = Array.isArray(response.data) ? response.data : [];

  return rows.map((row) => ({
    destinationIndex: row.destinationIndex,
    distanceKm: row.distanceMeters
      ? Number((row.distanceMeters / 1000).toFixed(2))
      : null,
    durationMinutes: row.duration
      ? Math.max(1, Math.round(parseDurationSeconds(row.duration) / 60))
      : null,
    condition: row.condition || null,
    status: row.status || null,
  }));
};

module.exports = {
  geocodeAddress,
  reverseGeocode,
  computeRoute,
  computeRouteMatrix,
};