const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const riderSettingsController = require('../controllers/riderSettingsController');

router.use(authMiddleware);

router.get('/', riderSettingsController.getSettingsSummary);

module.exports = router;