const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const authMiddleware = require('../middlewares/authMiddleware');
const multer = require('multer');

router.get('/me/profile', authMiddleware, userController.getMyProfile);

router.put('/me/profile', authMiddleware, userController.updateMyProfile);

router.get('/me/role-options', authMiddleware, userController.getRoleOptions);

router.patch(
  '/me/profile-picture',
  authMiddleware,
  multer().single('profile_picture'),
  userController.updateProfilePicture
);

module.exports = router;