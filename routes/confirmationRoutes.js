const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const confirmationController = require('../controllers/confirmationController');

router.use(authMiddleware);

router.get('/status', confirmationController.getConfirmationStatus);
router.post('/select-mode', confirmationController.selectMode);

module.exports = router;