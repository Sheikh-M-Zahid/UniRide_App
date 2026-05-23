const pool = require('../config/rideDb');

// ─────────────────────────────────────────────────
// GET /api/fare/settings  (admin only)
// ─────────────────────────────────────────────────
const getFareSettings = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT DISTINCT ON (vehicle_type)
        rate_id, vehicle_type, base_fare, per_km_rate, effective_from
      FROM vehicle_rates
      WHERE is_active = true
      ORDER BY vehicle_type, effective_from DESC
    `);

    const bike = result.rows.find((r) => r.vehicle_type === 'bike');
    const car  = result.rows.find((r) => r.vehicle_type === 'car');

    return res.status(200).json({
      success: true,
      data: {
        bike: bike
          ? { baseFare: parseFloat(bike.base_fare), perKm: parseFloat(bike.per_km_rate), effectiveFrom: bike.effective_from }
          : { baseFare: 0, perKm: 0 },
        car: car
          ? { baseFare: parseFloat(car.base_fare),  perKm: parseFloat(car.per_km_rate),  effectiveFrom: car.effective_from }
          : { baseFare: 0, perKm: 0 },
      },
    });
  } catch (error) {
    console.error('getFareSettings error:', error);
    return res.status(500).json({ success: false, message: 'Failed to load fare settings.' });
  }
};

// ─────────────────────────────────────────────────
// PUT /api/fare/settings  (admin only)
// body: { bike: { baseFare, perKm }, car: { baseFare, perKm } }
// ─────────────────────────────────────────────────
const updateFareSettings = async (req, res) => {
  const { bike, car } = req.body;

  if (!bike || !car) {
    return res.status(400).json({ success: false, message: 'Both bike and car fare are required.' });
  }

  const bikeBase  = parseFloat(bike.baseFare);
  const bikePerKm = parseFloat(bike.perKm);
  const carBase   = parseFloat(car.baseFare);
  const carPerKm  = parseFloat(car.perKm);

  if (isNaN(bikeBase) || isNaN(bikePerKm) || isNaN(carBase) || isNaN(carPerKm)) {
    return res.status(400).json({ success: false, message: 'Please enter valid numbers in all fields.' });
  }

  if (bikeBase < 0 || bikePerKm <= 0 || carBase < 0 || carPerKm <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Base fare must be >= 0 and per km fare must be > 0.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // পুরনো active records deactivate
    await client.query(`
      UPDATE vehicle_rates SET is_active = false
      WHERE vehicle_type IN ('bike', 'car') AND is_active = true
    `);

    // নতুন bike rate
    await client.query(`
      INSERT INTO vehicle_rates (vehicle_type, base_fare, per_km_rate, is_active, effective_from)
      VALUES ('bike', $1, $2, true, CURRENT_TIMESTAMP)
    `, [bikeBase, bikePerKm]);

    // নতুন car rate
    await client.query(`
      INSERT INTO vehicle_rates (vehicle_type, base_fare, per_km_rate, is_active, effective_from)
      VALUES ('car', $1, $2, true, CURRENT_TIMESTAMP)
    `, [carBase, carPerKm]);

    await client.query('COMMIT');

    return res.status(200).json({
      success: true,
      message: 'Fare updated successfully.',
      data: {
        bike: { baseFare: bikeBase, perKm: bikePerKm },
        car:  { baseFare: carBase,  perKm: carPerKm  },
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('updateFareSettings error:', error);
    return res.status(500).json({ success: false, message: 'Failed to update fare settings.' });
  } finally {
    client.release();
  }
};

// ─────────────────────────────────────────────────
// GET /api/fare/active/:vehicleType  (public — passenger/rider)
// ─────────────────────────────────────────────────
const getActiveFare = async (req, res) => {
  const { vehicleType } = req.params;

  if (!['bike', 'car'].includes(vehicleType)) {
    return res.status(400).json({ success: false, message: "vehicleType must be 'bike' or 'car'." });
  }

  try {
    const result = await pool.query(`
      SELECT base_fare, per_km_rate
      FROM vehicle_rates
      WHERE vehicle_type = $1 AND is_active = true
      ORDER BY effective_from DESC
      LIMIT 1
    `, [vehicleType]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'No active fare found.' });
    }

    const row = result.rows[0];
    return res.status(200).json({
      success: true,
      data: {
        vehicleType,
        baseFare: parseFloat(row.base_fare),
        perKm:    parseFloat(row.per_km_rate),
      },
    });
  } catch (error) {
    console.error('getActiveFare error:', error);
    return res.status(500).json({ success: false, message: 'Failed to load active fare.' });
  }
};

module.exports = { getFareSettings, updateFareSettings, getActiveFare };
