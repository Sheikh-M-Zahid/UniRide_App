const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const privacyController = require('../controllers/privacyController');

router.use(authMiddleware);

router.get('/', privacyController.getPrivacyData);
router.patch('/location-access', privacyController.updateLocationAccess);
router.patch('/profile-visibility', privacyController.updateProfileVisibility);
router.patch('/phone-privacy', privacyController.updatePhonePrivacy);
router.post('/download', privacyController.requestDataDownload);

module.exports = router;