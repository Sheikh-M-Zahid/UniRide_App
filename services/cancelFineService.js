const rideDb = require('../config/rideDb');

const getEarlyCancelCount = async (client, riderId) => {
  const { rows } = await client.query(
    `SELECT COUNT(*)::int AS total
     FROM ride_requests
     WHERE rider_id = $1
       AND status = 'cancelled'
       AND cancelled_by = $1
       AND confirmed_at IS NOT NULL
       AND free_cancel_until IS NOT NULL
       AND updated_at <= free_cancel_until`,
    [riderId]
  );

  return rows[0].total;
};

const calculateCancelFine = async ({ client, riderId, confirmedAt, freeCancelUntil }) => {
  const now = new Date();
  const isEarlyCancel = freeCancelUntil && now <= new Date(freeCancelUntil);

  if (!isEarlyCancel) {
    return {
      fineAmount: 10,
      fineType: 'late_cancel_fine',
      isFreeCancelAvailable: false,
    };
  }

  const earlyCancelCount = await getEarlyCancelCount(client, riderId);

  if (earlyCancelCount === 0) {
    return {
      fineAmount: 0,
      fineType: 'first_early_cancel_free',
      isFreeCancelAvailable: true,
    };
  }

  return {
    fineAmount: 5,
    fineType: 'repeat_early_cancel_fine',
    isFreeCancelAvailable: true,
  };
};

module.exports = {
  calculateCancelFine,
};