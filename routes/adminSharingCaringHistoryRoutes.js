const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const adminSharingCaringHistoryController = require('../controllers/adminSharingCaringHistoryController');

router.use(adminAuthMiddleware);

router.get('/', adminSharingCaringHistoryController.getSharingCaringHistory);

module.exports = router;