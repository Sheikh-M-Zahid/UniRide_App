--Online / offline status
SELECT is_active
FROM rider_availability
WHERE rider_id = $1
LIMIT 1;

-- Today earnings
SELECT COALESCE(SUM(amount), 0) AS today_earnings
FROM transactions
WHERE user_id = $1
  AND type = 'credit'
  AND status = 'completed'
  AND DATE(created_at) = CURRENT_DATE;

--Current active ride
SELECT
  u.first_name,
  u.last_name,
  rr.pickup_location,
  rr.destination,
  rr.estimated_fare,
  r.status
FROM ride_requests rr
INNER JOIN users u
  ON u.user_id = rr.passenger_id
INNER JOIN rides r
  ON r.ride_id = rr.ride_id
WHERE rr.rider_id = $1
  AND rr.status = 'accepted'
  AND r.status IN ('assigned', 'ongoing')
ORDER BY rr.confirmed_at DESC
LIMIT 1;

-- Upcoming reserved ride
SELECT
  start_location,
  destination,
  travel_date,
  travel_time
FROM rides
WHERE rider_id = $1
  AND status = 'assigned'
  AND travel_date IS NOT NULL
  AND travel_date >= CURRENT_DATE
ORDER BY travel_date ASC, travel_time ASC
LIMIT 1;