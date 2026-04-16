const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const controller = require('../controllers/securityController');

router.use(authMiddleware);

// GET security summary
router.get('/', controller.getSecuritySummary);

// PATCH emergency contact
router.patch('/emergency-contact', controller.updateEmergencyContact);

// PATCH change password
router.patch('/change-password', controller.changePassword);

module.exports = router;