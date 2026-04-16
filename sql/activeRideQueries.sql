-- 1. Upsert rider availability
INSERT INTO rider_availability (
    rider_id,
    is_active,
    current_latitude,
    current_longitude,
    last_activated_at,
    updated_at
)
VALUES (
    $1,
    $2,
    $3,
    $4,
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
RETURNING *;


-- 2. Get rider availability
SELECT *
FROM rider_availability
WHERE rider_id = $1;


-- 3. Get pending requests for rider
SELECT
    rr.request_id,
    rr.pickup_location,
    rr.destination,
    rr.estimated_fare,
    rr.estimated_minutes,
    rr.status,
    rr.requested_at,
    rr.expires_at,
    u.first_name,
    u.last_name,
    u.phone
FROM ride_requests rr
JOIN users u
  ON u.user_id = rr.passenger_id
WHERE rr.rider_id = $1
  AND rr.status = 'pending'
  AND rr.expires_at > CURRENT_TIMESTAMP
ORDER BY rr.requested_at DESC;


-- 4. Get current confirmed ride summary
SELECT
    rr.request_id,
    rr.ride_id,
    rr.status AS request_status,
    rr.pickup_location,
    rr.destination,
    rr.estimated_fare,
    rr.estimated_minutes,
    rr.confirmed_at,
    rr.free_cancel_until,
    u.first_name,
    u.last_name,
    u.phone,
    r.status AS ride_status
FROM ride_requests rr
JOIN users u
  ON u.user_id = rr.passenger_id
LEFT JOIN rides r
  ON r.ride_id = rr.ride_id
WHERE rr.rider_id = $1
  AND rr.status = 'accepted'
  AND (r.status IS NULL OR r.status IN ('assigned', 'ongoing'))
ORDER BY rr.confirmed_at DESC
LIMIT 1;


-- 5. Lock request for accept
SELECT *
FROM ride_requests
WHERE request_id = $1
FOR UPDATE;


-- 6. Check rider already has active ride
SELECT rr.request_id, rr.ride_id
FROM ride_requests rr
LEFT JOIN rides r
  ON r.ride_id = rr.ride_id
WHERE rr.rider_id = $1
  AND rr.status = 'accepted'
  AND (r.status IS NULL OR r.status IN ('assigned', 'ongoing'))
LIMIT 1;


-- 7. Create ride after accept
INSERT INTO rides (
    rider_id,
    vehicle_id,
    start_location,
    destination,
    total_distance_km,
    per_km_rate,
    total_fare,
    available_seats,
    status,
    travel_date,
    travel_time,
    vehicle_type,
    gender_preference,
    note
)
VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, 'assigned', $9, $10, $11, $12, $13
)
RETURNING *;


-- 8. Update request after accept
UPDATE ride_requests
SET
    status = 'accepted',
    responded_at = CURRENT_TIMESTAMP,
    confirmed_at = CURRENT_TIMESTAMP,
    free_cancel_until = CURRENT_TIMESTAMP + INTERVAL '5 minutes',
    ride_id = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE request_id = $1
RETURNING *;


-- 9. Insert participant
INSERT INTO ride_participants (
    ride_id,
    passenger_id,
    fare,
    confirmed
)
VALUES ($1, $2, $3, true)
RETURNING *;


-- 10. Reject request
UPDATE ride_requests
SET
    status = 'rejected',
    responded_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE request_id = $1
  AND rider_id = $2
  AND status = 'pending'
RETURNING *;


-- 11. Cancel confirmed ride within free window
UPDATE ride_requests
SET
    status = 'cancelled',
    cancel_reason = $2,
    cancelled_by = $3,
    responded_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE request_id = $1
RETURNING *;


-- 12. Cancel ride row
UPDATE rides
SET
    status = 'cancelled'
WHERE ride_id = $1
RETURNING *;


-- 13. Start ride
UPDATE rides
SET status = 'ongoing'
WHERE ride_id = $1
  AND rider_id = $2
  AND status = 'assigned'
RETURNING *;


-- 14. Complete ride
UPDATE rides
SET status = 'completed'
WHERE ride_id = $1
  AND rider_id = $2
  AND status = 'ongoing'
RETURNING *;


-- 15. Expire old pending requests
UPDATE ride_requests
SET
    status = 'expired',
    updated_at = CURRENT_TIMESTAMP
WHERE status = 'pending'
  AND expires_at <= CURRENT_TIMESTAMP
RETURNING request_id, rider_id, passenger_id;