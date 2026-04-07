const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const uploadProfileImage = require('../middlewares/uploadProfileImage');
const riderProfileController = require('../controllers/riderProfileController');

router.use(authMiddleware);

router.get('/', riderProfileController.getProfile);
router.patch(
  '/image',
  uploadProfileImage.single('profilePicture'),
  riderProfileController.uploadProfileImage
);

module.exports = router;