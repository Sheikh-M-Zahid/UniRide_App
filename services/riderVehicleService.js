const rideDb = require('../config/rideDb');

/* =========================
   FILE URL HELPER
========================= */
const buildFileUrl = (req, path) => {
  if (!path) return null;

  if (path.startsWith('http')) return path;

  const base = `${req.protocol}://${req.get('host')}`;
  return `${base}${path}`;
};

/* =========================
   VEHICLE LIST
========================= */
const getMyVehicles = async (userId) => {
  const res = await rideDb.query(
    `
    SELECT
      vehicle_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      verified
    FROM vehicles
    WHERE user_id = $1
    ORDER BY created_at DESC
  `,
    [userId]
  );

  return res.rows.map(v => ({
    vehicleId: v.vehicle_id,
    vehicleType: v.vehicle_type,
    brand: v.company,
    model: v.model,
    year: v.year,
    numberPlate: v.number_plate,
    verified: v.verified,
  }));
};

/* =========================
   DOCUMENT MAPPER
========================= */
const buildDocuments = (vehicle, req) => {
  const status = vehicle.verified ? 'Verified' : 'Pending';

  const docs = [
    {
      title: 'University ID',
      fileUrl: buildFileUrl(req, vehicle.varsity_id_photo),
      status,
    },
    {
      title: 'Profile Photo',
      fileUrl: buildFileUrl(req, vehicle.driver_profile_photo),
      status,
    },
    {
      title: 'Driving License',
      fileUrl: buildFileUrl(req, vehicle.driving_license_photo),
      status,
    },
    {
      title: 'Vehicle Registration',
      fileUrl: buildFileUrl(req, vehicle.vehicle_registration_photo),
      status,
    },
    {
      title: 'Tax Token',
      fileUrl: buildFileUrl(req, vehicle.tax_token_photo),
      status,
    },
  ];

  // null remove (optional clean response)
  return docs.filter(d => d.fileUrl !== null);
};

/* =========================
   VEHICLE DOCUMENTS
========================= */
const getVehicleDocuments = async ({ userId, vehicleId, req }) => {
  const res = await rideDb.query(
    `
    SELECT *
    FROM vehicles
    WHERE vehicle_id = $1
  `,
    [vehicleId]
  );

  if (!res.rows.length) {
    throw new Error('Vehicle not found');
  }

  const vehicle = res.rows[0];

  // 🔒 ownership check
  if (vehicle.user_id !== userId) {
    throw new Error('Unauthorized access');
  }

  const documents = buildDocuments(vehicle, req);

  return {
    vehicleId: vehicle.vehicle_id,
    vehicleName: `${vehicle.company} ${vehicle.model}`,
    documents,
  };
};

module.exports = {
  getMyVehicles,
  getVehicleDocuments,
};