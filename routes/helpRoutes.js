const express = require('express');
const router = express.Router();

const helpController = require('../controllers/helpController');
const authMiddleware = require('../middlewares/authMiddleware');

// PUBLIC
router.get('/faqs', helpController.getFaqs);

// PRIVATE
router.post('/submit', authMiddleware, helpController.submitHelpRequest);

module.exports = router;
