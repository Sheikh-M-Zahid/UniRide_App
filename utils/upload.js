const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/alumni/'),
  filename: (req, file, cb) => {
    cb(null, uuidv4() + path.extname(file.originalname));
  },
});

const upload = multer({ storage });

exports.alumniUpload = upload.fields([
  { name: 'alumni_card_photo', maxCount: 1 },
  { name: 'transcript_photo', maxCount: 1 },
]);
