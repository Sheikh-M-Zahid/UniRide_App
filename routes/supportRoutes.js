const express = require('express');
const router = express.Router();

const supportController = require('../controllers/supportController');
const authMiddleware = require('../middlewares/authMiddleware');

router.post('/help', authMiddleware, supportController.submitHelpRequest);
router.get('/my-requests', authMiddleware, supportController.getMyRequests);

module.exports = router;