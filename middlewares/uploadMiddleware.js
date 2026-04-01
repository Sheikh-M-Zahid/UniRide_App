const multer = require('multer');
const path = require('path');
const fs = require('fs');

/* =========================
   CREATE FOLDERS
========================= */
const vehicleDir = path.join(__dirname, '..', 'uploads', 'vehicles');
const profileDir = path.join(__dirname, '..', 'uploads', 'profile-pictures');

[vehicleDir, profileDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/* =========================
   COMMON FILE FILTER
========================= */
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'application/pdf',
  ];

  if (!allowedMimeTypes.includes(file.mimetype)) {
    return cb(
      new Error('Only jpg, jpeg, png, webp, and pdf files are allowed.')
    );
  }

  cb(null, true);
};

/* =========================
   VEHICLE STORAGE
========================= */
const vehicleStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, vehicleDir);
  },
  filename: (req, file, cb) => {
    const uniqueName =
      Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueName + path.extname(file.originalname));
  },
});

const vehicleUpload = multer({
  storage: vehicleStorage,
  fileFilter,
  limits: {
    fileSize: 8 * 1024 * 1024,
  },
}).fields([
  { name: 'varsity_id_photo', maxCount: 1 },
  { name: 'driver_profile_photo', maxCount: 1 },
  { name: 'driving_license_photo', maxCount: 1 },
  { name: 'vehicle_registration_photo', maxCount: 1 },
  { name: 'tax_token_photo', maxCount: 1 },
]);

/* =========================
   PROFILE PICTURE STORAGE
========================= */
const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, profileDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const safeName = `profile-${req.user.userId}-${Date.now()}${ext}`;
    cb(null, safeName);
  },
});

const uploadProfilePicture = multer({
  storage: profileStorage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
}).single('profile_picture');

module.exports = {
  vehicleUpload,
  uploadProfilePicture,
};