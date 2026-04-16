const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const controller = require('../controllers/adminTopLocationController');

router.use(adminAuthMiddleware);

router.get('/', controller.getTopLocationStats);

module.exports = router;