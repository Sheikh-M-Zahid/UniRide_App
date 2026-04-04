const rideDb = require('../config/rideDb');

const runWeeklyDueCheck = async () => {
  await rideDb.query(`
    UPDATE users
    SET account_status = 'suspended'
    WHERE due_balance > 0
  `);

  console.log('Weekly suspension applied');
};

module.exports = { runWeeklyDueCheck };