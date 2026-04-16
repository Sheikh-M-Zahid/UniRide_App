const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const { uploadProfilePicture } = require('../middlewares/uploadMiddleware');
const adminProfileController = require('../controllers/adminProfileController');

router.use(adminAuthMiddleware);

router.get('/', adminProfileController.getAdminProfile);

router.patch('/edit', adminProfileController.updateAdminProfile);

router.patch(
  '/image',
  uploadProfilePicture.single('profilePicture'),
  adminProfileController.updateAdminProfileImage
);

module.exports = router;