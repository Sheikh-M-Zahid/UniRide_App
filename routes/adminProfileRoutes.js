const express = require('express');
const multer = require('multer');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const { uploadProfilePicture } = require('../middlewares/uploadMiddleware');
const adminProfileController = require('../controllers/adminProfileController');

router.use(adminAuthMiddleware);

router.get('/', adminProfileController.getAdminProfile);

router.patch('/edit', adminProfileController.updateAdminProfile);

router.patch('/image', (req, res, next) => {
  uploadProfilePicture.single('profilePicture')(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({
        success: false,
        message: err.message,
      });
    }

    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message || 'File upload failed.',
      });
    }

    next();
  });
}, adminProfileController.updateAdminProfileImage);

module.exports = router;