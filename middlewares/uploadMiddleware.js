const multer = require('multer');
const path = require('path');
const fs = require('fs');

const profileDir = path.join(__dirname, '..', 'uploads', 'profile-pictures');
const vehicleDir = path.join(__dirname, '..', 'uploads', 'vehicles');

[profileDir, vehicleDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  if (!allowedMimeTypes.includes(file.mimetype)) {
    return cb(new Error('Only jpg, jpeg, png, and webp images are allowed.'));
  }

  cb(null, true);
};

const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileDir),
  filename: (req, file, cb) => {
    const uniqueName = `profile-${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const vehicleStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, vehicleDir),
  filename: (req, file, cb) => {
    const uniqueName = `vehicle-${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const uploadProfilePicture = multer({
  storage: profileStorage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
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

module.exports = {
  uploadProfilePicture,
  vehicleUpload,
};