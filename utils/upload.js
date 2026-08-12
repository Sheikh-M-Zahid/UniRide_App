const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'uniride/alumni',
    allowed_formats: ['jpg', 'jpeg', 'png'],
  },
});

const upload = multer({ storage });

exports.alumniUpload = upload.fields([
  { name: 'alumni_card_photo', maxCount: 1 },
  { name: 'transcript_photo', maxCount: 1 },
]);
