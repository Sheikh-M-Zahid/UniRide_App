const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const profileController = require('../controllers/profileController');
const { uploadProfilePicture } = require('../middlewares/uploadMiddleware');

router.use(authMiddleware);

// profile summary
router.get('/me', profileController.getMyProfile);

// update profile image
router.patch(
  '/image',
  uploadProfilePicture.single('profile_picture'),
  profileController.updateProfileImage
);

module.exports = router;