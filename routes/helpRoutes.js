const express = require('express');
const router = express.Router();

const helpController = require('../controllers/helpController');

// PUBLIC
router.get('/faqs', helpController.getFaqs);

module.exports = router;