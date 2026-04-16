--Get rider vehicle
SELECT vehicle_id, vehicle_type
FROM vehicles
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 1;
--Get latest active rate
SELECT per_km_rate
FROM vehicle_rates
WHERE vehicle_type = $1
  AND is_active = true
ORDER BY effective_from DESC
LIMIT 1;
--Create request
INSERT INTO ride_requests (
    passenger_id, rider_id, pickup_location, destination,
    pickup_latitude, pickup_longitude,
    destination_latitude, destination_longitude,
    estimated_fare, estimated_minutes, status, expires_at,
    distance_km, rate_per_km, vehicle_type
)
VALUES (
    $1, $2, $3, $4,
    $5, $6, $7, $8,
    $9, $10, 'pending',
    CURRENT_TIMESTAMP + INTERVAL '45 seconds',
    $11, $12, $13
)
RETURNING *;
--Accept request
UPDATE ride_requests
SET
  status = 'accepted',
  ride_id = $2,
  responded_at = CURRENT_TIMESTAMP,
  confirmed_at = CURRENT_TIMESTAMP,
  free_cancel_until = CURRENT_TIMESTAMP + INTERVAL '5 minutes',
  updated_at = CURRENT_TIMESTAMP
WHERE request_id = $1
RETURNING *;
--Create ride
INSERT INTO rides (
    rider_id, vehicle_id, start_location, destination,
    total_distance_km, per_km_rate, total_fare,
    available_seats, status, travel_date, vehicle_type
)
VALUES (
    $1, $2, $3, $4,
    $5, $6, $7,
    1, 'assigned', CURRENT_DATE, $8
)
RETURNING *;
--Add participant
INSERT INTO ride_participants (ride_id, passenger_id, fare, confirmed)
VALUES ($1, $2, $3, true);
--Cancel confirmed request
UPDATE ride_requests
SET
  status = 'cancelled',
  cancel_reason = $2,
  cancelled_by = $3,
  responded_at = CURRENT_TIMESTAMP,
  updated_at = CURRENT_TIMESTAMP
WHERE request_id = $1;
--Cancel ride
UPDATE rides
SET status = 'cancelled'
WHERE ride_id = $1;
--Increase due balance
UPDATE users
SET due_balance = due_balance + $2
WHERE user_id = $1
RETURNING due_balance;
--Insert fine transaction
INSERT INTO transactions (
    user_id,
    amount,
    type,
    method,
    reference_id,
    status
)
VALUES ($1, $2, 'debit', 'cancel_fine', $3, 'completed');