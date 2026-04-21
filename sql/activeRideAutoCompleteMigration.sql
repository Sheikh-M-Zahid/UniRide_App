-- 1) rides status constraint ঠিক করা
ALTER TABLE rides
DROP CONSTRAINT IF EXISTS rides_status_check;

ALTER TABLE rides
ADD CONSTRAINT rides_status_check
CHECK (status IN ('active', 'assigned', 'accepted', 'ongoing', 'completed', 'cancelled'));

-- 2) missing columns থাকলে add করা
ALTER TABLE rides
ADD COLUMN IF NOT EXISTS pickup_latitude NUMERIC(10,7),
ADD COLUMN IF NOT EXISTS pickup_longitude NUMERIC(10,7),
ADD COLUMN IF NOT EXISTS destination_latitude NUMERIC(10,7),
ADD COLUMN IF NOT EXISTS destination_longitude NUMERIC(10,7),
ADD COLUMN IF NOT EXISTS start_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS start_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP NULL;

-- 3) useful indexes
CREATE INDEX IF NOT EXISTS idx_rides_rider_status_created
ON rides(rider_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_rides_destination_coords
ON rides(destination_latitude, destination_longitude);

CREATE INDEX IF NOT EXISTS idx_live_locations_user_ride
ON live_locations(user_id, ride_id);

CREATE INDEX IF NOT EXISTS idx_rider_availability_rider
ON rider_availability(rider_id);

-- 4) optional unique protection for same user + same ride live location
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'live_locations_user_id_ride_id_unique'
  ) THEN
    ALTER TABLE live_locations
    ADD CONSTRAINT live_locations_user_id_ride_id_unique UNIQUE (user_id, ride_id);
  END IF;
END $$;