const rideDb = require('../config/rideDb');
const { calculateCancelFine } = require('./cancelFineService');

const getRemainingSeconds = (futureTime) => {
  if (!futureTime) return 0;
  const diff = new Date(futureTime).getTime() - Date.now();
  return diff > 0 ? Math.floor(diff / 1000) : 0;
};

const updateAvailability = async ({ riderId, body, io }) => {
  const { isActive, latitude = null, longitude = null } = body;

  const { rows } = await rideDb.query(
    `INSERT INTO rider_availability (
        rider_id, is_active, current_latitude, current_longitude,
        last_activated_at, updated_at
     )
     VALUES (
        $1, $2, $3, $4,
        CASE WHEN $2 = true THEN CURRENT_TIMESTAMP ELSE NULL END,
        CURRENT_TIMESTAMP
     )
     ON CONFLICT (rider_id)
     DO UPDATE SET
        is_active = EXCLUDED.is_active,
        current_latitude = EXCLUDED.current_latitude,
        current_longitude = EXCLUDED.current_longitude,
        last_activated_at = CASE
          WHEN EXCLUDED.is_active = true THEN CURRENT_TIMESTAMP
          ELSE rider_availability.last_activated_at
        END,
        last_deactivated_at = CASE
          WHEN EXCLUDED.is_active = false THEN CURRENT_TIMESTAMP
          ELSE rider_availability.last_deactivated_at
        END,
        updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [riderId, isActive, latitude, longitude]
  );

  const data = {
    riderId,
    rideIsActive: rows[0].is_active,
    updatedAt: rows[0].updated_at,
  };

  if (io) {
    io.to(`rider:${riderId}`).emit('rider:availability:updated', data);
  }

  return data;
};

const mapConfirmedRide = (row) => {
  const remainingFreeCancelSeconds = getRemainingSeconds(row.free_cancel_until);

  return {
    requestId: row.request_id,
    confirmedRideId: row.ride_id,
    passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    phoneNumber: row.phone,
    currentLocation: row.pickup_location,
    destination: row.destination,
    distanceKm: Number(row.distance_km || 0),
    fare: Number(row.estimated_fare || 0),
    estimatedMinutes: row.estimated_minutes || 0,
    confirmedAt: row.confirmed_at,
    remainingFreeCancelSeconds,
    isFreeCancelAvailable: remainingFreeCancelSeconds > 0,
    status: row.ride_status || row.request_status,
  };
};

const getPendingRequests = async ({ riderId }) => {
  const { rows } = await rideDb.query(
    `SELECT
        rr.request_id,
        rr.pickup_location,
        rr.destination,
        rr.distance_km,
        rr.estimated_fare,
        rr.estimated_minutes,
        rr.status,
        u.first_name,
        u.last_name,
        u.phone
     FROM ride_requests rr
     JOIN users u ON u.user_id = rr.passenger_id
     WHERE rr.rider_id = $1
       AND rr.status = 'pending'
       AND rr.expires_at > CURRENT_TIMESTAMP
     ORDER BY rr.requested_at ASC`,
    [riderId]
  );

  return rows.map((row) => ({
    requestId: row.request_id,
    passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    phoneNumber: row.phone,
    currentLocation: row.pickup_location,
    destination: row.destination,
    distanceKm: Number(row.distance_km || 0),
    fare: Number(row.estimated_fare || 0),
    estimatedMinutes: row.estimated_minutes || 0,
    status: row.status,
  }));
};

const getDashboard = async ({ riderId }) => {
  const [availabilityRes, confirmedRes, pendingRequests] = await Promise.all([
    rideDb.query(`SELECT is_active FROM rider_availability WHERE rider_id = $1`, [riderId]),
    rideDb.query(
      `SELECT
          rr.request_id,
          rr.ride_id,
          rr.pickup_location,
          rr.destination,
          rr.distance_km,
          rr.estimated_fare,
          rr.estimated_minutes,
          rr.confirmed_at,
          rr.free_cancel_until,
          rr.status AS request_status,
          r.status AS ride_status,
          u.first_name,
          u.last_name,
          u.phone
       FROM ride_requests rr
       JOIN users u ON u.user_id = rr.passenger_id
       LEFT JOIN rides r ON r.ride_id = rr.ride_id
       WHERE rr.rider_id = $1
         AND rr.status = 'accepted'
         AND (r.status IS NULL OR r.status IN ('assigned', 'ongoing'))
       ORDER BY rr.confirmed_at DESC
       LIMIT 1`,
      [riderId]
    ),
    getPendingRequests({ riderId }),
  ]);

  return {
    rideIsActive: availabilityRes.rows[0]?.is_active || false,
    confirmedRide: confirmedRes.rows[0] ? mapConfirmedRide(confirmedRes.rows[0]) : null,
    pendingRequests,
  };
};

const acceptRideRequest = async ({ riderId, requestId, io }) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const requestRes = await client.query(
      `SELECT *
       FROM ride_requests
       WHERE request_id = $1
       FOR UPDATE`,
      [requestId]
    );

    if (!requestRes.rows.length) throw new Error('Ride request not found.');

    const request = requestRes.rows[0];

    if (request.rider_id !== riderId) throw new Error('Unauthorized request access.');
    if (request.status !== 'pending') throw new Error('Request already handled.');
    if (new Date(request.expires_at) <= new Date()) throw new Error('Request expired.');

    const activeRideRes = await client.query(
      `SELECT rr.request_id
       FROM ride_requests rr
       LEFT JOIN rides r ON r.ride_id = rr.ride_id
       WHERE rr.rider_id = $1
         AND rr.status = 'accepted'
         AND (r.status IS NULL OR r.status IN ('assigned', 'ongoing'))
       LIMIT 1`,
      [riderId]
    );

    if (activeRideRes.rows.length) {
      throw new Error('Rider already has an active confirmed ride.');
    }

    const vehicleRes = await client.query(
      `SELECT vehicle_id, vehicle_type
       FROM vehicles
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [riderId]
    );

    const vehicle = vehicleRes.rows[0];
    if (!vehicle) throw new Error('Vehicle not found.');

    const rideRes = await client.query(
      `INSERT INTO rides (
          rider_id, vehicle_id, start_location, destination,
          total_distance_km, per_km_rate, total_fare,
          available_seats, status, travel_date, vehicle_type
       )
       VALUES (
          $1, $2, $3, $4, $5, $6, $7,
          1, 'assigned', CURRENT_DATE, $8
       )
       RETURNING *`,
      [
        riderId,
        vehicle.vehicle_id,
        request.pickup_location,
        request.destination,
        request.distance_km,
        request.rate_per_km,
        request.estimated_fare,
        request.vehicle_type || vehicle.vehicle_type,
      ]
    );

    const ride = rideRes.rows[0];

    await client.query(
      `INSERT INTO ride_participants (ride_id, passenger_id, fare, confirmed)
       VALUES ($1, $2, $3, true)`,
      [ride.ride_id, request.passenger_id, request.estimated_fare]
    );

    const updatedReqRes = await client.query(
      `UPDATE ride_requests
       SET
         status = 'accepted',
         ride_id = $2,
         responded_at = CURRENT_TIMESTAMP,
         confirmed_at = CURRENT_TIMESTAMP,
         free_cancel_until = CURRENT_TIMESTAMP + INTERVAL '5 minutes',
         updated_at = CURRENT_TIMESTAMP
       WHERE request_id = $1
       RETURNING *`,
      [requestId, ride.ride_id]
    );

    await client.query('COMMIT');

    const dashboard = await getDashboard({ riderId });

    if (io) {
      io.to(`rider:${riderId}`).emit('ride-request:accepted', dashboard.confirmedRide);
      io.to(`rider:${riderId}`).emit('active-ride:updated', dashboard);
      io.to(`user:${request.passenger_id}`).emit('ride-request:accepted', {
        requestId,
        confirmedRideId: ride.ride_id,
        status: 'accepted',
      });
    }

    return dashboard;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const rejectRideRequest = async ({ riderId, requestId, io }) => {
  const result = await rideDb.query(
    `UPDATE ride_requests
     SET status = 'rejected',
         responded_at = CURRENT_TIMESTAMP,
         updated_at = CURRENT_TIMESTAMP
     WHERE request_id = $1
       AND rider_id = $2
       AND status = 'pending'
     RETURNING *`,
    [requestId, riderId]
  );

  if (!result.rows.length) {
    throw new Error('Pending request not found or already handled.');
  }

  const request = result.rows[0];
  const dashboard = await getDashboard({ riderId });

  if (io) {
    io.to(`rider:${riderId}`).emit('ride-request:rejected', { requestId });
    io.to(`rider:${riderId}`).emit('active-ride:updated', dashboard);
    io.to(`user:${request.passenger_id}`).emit('ride-request:rejected', { requestId });
  }

  return dashboard;
};

const cancelConfirmedRide = async ({ riderId, requestId, io }) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const requestRes = await client.query(
      `SELECT *
       FROM ride_requests
       WHERE request_id = $1
       FOR UPDATE`,
      [requestId]
    );

    if (!requestRes.rows.length) throw new Error('Confirmed ride not found.');

    const request = requestRes.rows[0];

    if (request.rider_id !== riderId) throw new Error('Unauthorized cancellation.');
    if (request.status !== 'accepted') throw new Error('Ride is not in accepted state.');

    const rideRes = await client.query(
      `SELECT *
       FROM rides
       WHERE ride_id = $1
       FOR UPDATE`,
      [request.ride_id]
    );

    if (!rideRes.rows.length) throw new Error('Ride not found.');

    const ride = rideRes.rows[0];

    if (!['assigned', 'ongoing'].includes(ride.status)) {
      throw new Error('Ride cannot be cancelled now.');
    }

    const fineResult = await calculateCancelFine({
      client,
      riderId,
      confirmedAt: request.confirmed_at,
      freeCancelUntil: request.free_cancel_until,
    });

    await client.query(
      `UPDATE ride_requests
       SET
         status = 'cancelled',
         cancel_reason = $2,
         cancelled_by = $3,
         responded_at = CURRENT_TIMESTAMP,
         updated_at = CURRENT_TIMESTAMP
       WHERE request_id = $1`,
      [requestId, fineResult.fineType, riderId]
    );

    await client.query(
      `UPDATE rides
       SET status = 'cancelled'
       WHERE ride_id = $1`,
      [request.ride_id]
    );

    let updatedDueBalance = null;

    if (fineResult.fineAmount > 0) {
      const dueRes = await client.query(
        `UPDATE users
         SET due_balance = due_balance + $2
         WHERE user_id = $1
         RETURNING due_balance`,
        [riderId, fineResult.fineAmount]
      );

      updatedDueBalance = Number(dueRes.rows[0].due_balance);

      await client.query(
        `INSERT INTO transactions (
            user_id,
            amount,
            type,
            method,
            reference_id,
            status
         )
         VALUES ($1, $2, 'debit', 'cancel_fine', $3, 'completed')`,
        [riderId, fineResult.fineAmount, `CANCEL-FINE-${requestId}`]
      );
    }

    await client.query('COMMIT');

    const dashboard = await getDashboard({ riderId });

    if (io) {
      io.to(`rider:${riderId}`).emit('confirmed-ride:cancelled', {
        requestId,
        confirmedRideId: request.ride_id,
        fineAmount: fineResult.fineAmount,
        fineType: fineResult.fineType,
        dueBalance: updatedDueBalance,
      });

      io.to(`rider:${riderId}`).emit('active-ride:updated', dashboard);

      if (fineResult.fineAmount > 0) {
        io.to(`rider:${riderId}`).emit('rider:due-balance:updated', {
          fineAmount: fineResult.fineAmount,
          dueBalance: updatedDueBalance,
        });
      }

      io.to(`user:${request.passenger_id}`).emit('confirmed-ride:cancelled', {
        requestId,
        confirmedRideId: request.ride_id,
        cancelledBy: riderId,
      });
    }

    return {
      dashboard,
      fineAmount: fineResult.fineAmount,
      fineType: fineResult.fineType,
      dueBalance: updatedDueBalance,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const startRide = async ({ riderId, rideId, io }) => {
  const result = await rideDb.query(
    `UPDATE rides
     SET status = 'ongoing'
     WHERE ride_id = $1
       AND rider_id = $2
       AND status = 'assigned'
     RETURNING *`,
    [rideId, riderId]
  );

  if (!result.rows.length) throw new Error('Ride not found or cannot be started.');

  if (io) {
    io.to(`ride:${rideId}`).emit('ride:ongoing', {
      rideId,
      status: 'ongoing',
    });
  }

  return result.rows[0];
};

const completeRide = async ({ riderId, rideId, io }) => {
  const result = await rideDb.query(
    `UPDATE rides
     SET status = 'completed'
     WHERE ride_id = $1
       AND rider_id = $2
       AND status = 'ongoing'
     RETURNING *`,
    [rideId, riderId]
  );

  if (!result.rows.length) throw new Error('Ride not found or cannot be completed.');

  if (io) {
    io.to(`ride:${rideId}`).emit('ride:completed', {
      rideId,
      status: 'completed',
    });
  }

  return result.rows[0];
};

module.exports = {
  updateAvailability,
  getPendingRequests,
  getDashboard,
  acceptRideRequest,
  rejectRideRequest,
  cancelConfirmedRide,
  startRide,
  completeRide,
};