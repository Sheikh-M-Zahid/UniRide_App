const express = require('express');
const router = express.Router();

const servicesController = require('../controllers/servicesController');

// Public route (no auth needed)
router.get('/summary', servicesController.getServicesSummary);

module.exports = router;