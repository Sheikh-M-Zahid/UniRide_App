const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const earningsController = require('../controllers/earningsController');

router.get('/', authMiddleware, earningsController.getEarningsDashboard);

module.exports = router;