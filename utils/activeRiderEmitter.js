const { getIO } = require('../config/socket');
const activeRiderService = require('../services/activeRiderService');

const emitActiveRidersUpdate = async () => {
  try {
    const io = getIO();

    const latestData = await activeRiderService.getActiveRiders({
      search: '',
      filter: 'all_active',
      location: '',
      page: 1,
      limit: 20,
    });

    io.to('active_riders_room').emit('active_riders_updated', latestData);
  } catch (error) {
    console.error('emitActiveRidersUpdate error:', error.message);
  }
};

module.exports = {
  emitActiveRidersUpdate,
};