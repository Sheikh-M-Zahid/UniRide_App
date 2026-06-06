const axios = require('axios');

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

const ensureApiKey = () => {
  if (!GOOGLE_MAPS_API_KEY) {
    throw new Error('GOOGLE_MAPS_API_KEY is missing.');
  }
};

const validateLatLng = ({ lat, lng }) => {
  if (Number.isNaN(lat) || lat < -90 || lat > 90) {
    throw new Error('Invalid latitude.');
  }

  if (Number.isNaN(lng) || lng < -180 || lng > 180) {
    throw new Error('Invalid longitude.');
  }
};

const normalizeAddressText = (value) => {
  return String(value || '')
    .replace(/\s+/g, ' ')
    .trim();
};

const pickBestReverseGeocodeAddress = (results = []) => {
  if (!Array.isArray(results) || results.length === 0) return '';

  const preferredTypeGroups = [
    ['street_address'],
    ['premise'],
    ['subpremise'],
    ['route'],
    ['neighborhood'],
    ['sublocality', 'sublocality_level_1'],
    ['locality'],
    ['administrative_area_level_2'],
    ['administrative_area_level_1'],
  ];

  for (const group of preferredTypeGroups) {
    const match = results.find((item) => {
      const types = Array.isArray(item.types) ? item.types : [];
      return group.every((type) => types.includes(type));
    });

    if (match?.formatted_address) {
      return normalizeAddressText(match.formatted_address);
    }
  }

  const firstWithAddress = results.find((item) => item?.formatted_address);

  return normalizeAddressText(firstWithAddress?.formatted_address || '');
};

//AUTOCOMPLETE (Places API New)
const autocomplete = async (input) => {
  ensureApiKey();

  const response = await axios.post(
    'https://places.googleapis.com/v1/places:autocomplete',
    {
      input,
      includedRegionCodes: ['bd'],
      regionCode: 'BD',
      languageCode: 'en',
      includeQueryPredictions: false,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
      },
      timeout: 10000,
    }
  );

  const suggestions = response.data?.suggestions || [];

  return suggestions
    .filter((item) => item.placePrediction)
    .map((item) => {
      const prediction = item.placePrediction;
      const text = prediction.text?.text || '';
      const placeId = prediction.placeId || '';
      const structured = prediction.structuredFormat || {};

      return {
        place_id: placeId,
        description: text,
        main_text: structured.mainText?.text || text,
        secondary_text: structured.secondaryText?.text || '',
      };
    });
};

//PLACE DETAILS (Places API New)
const getPlaceDetails = async (placeId) => {
  ensureApiKey();

  const response = await axios.get(
    `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`,
    {
      headers: {
        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
        'X-Goog-FieldMask': 'id,formattedAddress,location',
      },
      timeout: 10000,
    }
  );

  const place = response.data;

  return {
    placeId: place.id,
    lat: place.location?.latitude ?? null,
    lng: place.location?.longitude ?? null,
    formattedAddress: normalizeAddressText(place.formattedAddress || ''),
  };
};

//REVERSE GEOCODE (Geocoding API)
const reverseGeocode = async ({ lat, lng }) => {
  ensureApiKey();
  validateLatLng({ lat, lng });

  const response = await axios.get(
    'https://maps.googleapis.com/maps/api/geocode/json',
    {
      params: {
        latlng: `${lat},${lng}`,
        key: GOOGLE_MAPS_API_KEY,
        language: 'en',
        region: 'bd',
      },
      timeout: 10000,
    }
  );

  const status = response.data?.status || '';
  const results = response.data?.results || [];

  if (status !== 'OK' || !results.length) {
    return {
      lat,
      lng,
      formattedAddress: '',
    };
  }

  return {
    lat,
    lng,
    formattedAddress: pickBestReverseGeocodeAddress(results),
  };
};

module.exports = {
  autocomplete,
  getPlaceDetails,
  reverseGeocode,
};
