CREATE INDEX IF NOT EXISTS idx_ride_participants_passenger_ride
ON ride_participants(passenger_id, ride_id);