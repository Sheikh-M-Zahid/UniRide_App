const riderOfferService = require('../services/riderOfferServices');

const getRiderOffers = async (req, res) => {
  try {
    const offers = await riderOfferService.getOffersForRider();

    return res.status(200).json({
      success: true,
      message: 'Offers fetched successfully',
      data: offers,
    });
  } catch (err) {
    console.error('[RiderOfferController] getRiderOffers error:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Failed to fetch offers',
      data: [],
    });
  }
};

module.exports = {
  getRiderOffers,
};
