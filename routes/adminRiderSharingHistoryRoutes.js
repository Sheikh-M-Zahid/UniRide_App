const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const adminRiderSharingHistoryController = require('../controllers/adminRiderSharingHistoryController');

router.use(adminAuthMiddleware);

router.get('/', adminRiderSharingHistoryController.getRiderSharingHistory);

module.exports = router;