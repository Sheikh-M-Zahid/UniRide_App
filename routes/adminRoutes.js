const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post('/login', validateRequiredFields(['email', 'password']), adminController.adminLogin);

router.get('/users', authMiddleware, adminMiddleware, adminController.listUsers);
router.get('/reports', authMiddleware, adminMiddleware, adminController.viewReports);
router.patch('/reports/:reportId/solve', authMiddleware, adminMiddleware, adminController.markReportSolved);
router.post(
  '/offers',
  authMiddleware,
  adminMiddleware,
  validateRequiredFields(['offer_name', 'offer_type', 'promo_code']),
  adminController.createOffer
);
router.get('/offers', authMiddleware, adminMiddleware, adminController.listOffers);
router.patch('/users/:userId/suspend', authMiddleware, adminMiddleware, adminController.suspendUser);
router.patch('/users/:userId/activate', authMiddleware, adminMiddleware, adminController.activateUser);

module.exports = router;