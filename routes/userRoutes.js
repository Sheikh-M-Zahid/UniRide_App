const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/profile', authMiddleware, userController.getProfile);
router.put('/profile', authMiddleware, userController.updateProfile);
router.get('/role', authMiddleware, userController.getRole);
router.get('/account-status', authMiddleware, userController.getAccountStatus);
router.get('/wallet', authMiddleware, userController.getWalletInfo);
router.get('/me/role-options', authMiddleware, userController.getRoleOptions);

module.exports = router;