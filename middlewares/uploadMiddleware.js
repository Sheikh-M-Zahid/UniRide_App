const multer = require('multer');
const path = require('path');
const fs = require('fs');

<<<<<<< HEAD
/* =========================
   CREATE FOLDERS
========================= */
const vehicleDir = path.join(__dirname, '..', 'uploads', 'vehicles');
const profileDir = path.join(__dirname, '..', 'uploads', 'profile-pictures');

[vehicleDir, profileDir].forEach((dir) => {
=======
const profileDir = path.join(__dirname, '..', 'uploads', 'profile-pictures');
const vehicleDir = path.join(__dirname, '..', 'uploads', 'vehicles');

[profileDir, vehicleDir].forEach((dir) => {
>>>>>>> master
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

<<<<<<< HEAD
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
=======
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/jpg',
    'image/webp',
  ];

  if (!allowedMimeTypes.includes(file.mimetype)) {
    return cb(new Error('Only jpg, jpeg, png, webp images are allowed.'));
>>>>>>> master
  }

  cb(null, true);
};

<<<<<<< HEAD
/* =========================
   VEHICLE STORAGE
========================= */
=======
// ===== Profile picture upload =====
const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, profileDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `profile-${Date.now()}${path.extname(file.originalname)}`;
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

// ===== Vehicle documents upload =====
>>>>>>> master
const vehicleStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, vehicleDir);
  },
  filename: (req, file, cb) => {
<<<<<<< HEAD
    const uniqueName =
      Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueName + path.extname(file.originalname));
=======
    const uniqueName = `vehicle-${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
>>>>>>> master
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

<<<<<<< HEAD
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
=======
module.exports = {
  uploadProfilePicture,
  vehicleUpload,
>>>>>>> master
};