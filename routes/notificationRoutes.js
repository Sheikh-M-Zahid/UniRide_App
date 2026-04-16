const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const controller = require('../controllers/notificationController');

router.use(auth);

router.get('/', controller.getNotifications);
router.patch('/:id/read', controller.markAsRead);
router.patch('/read-all', controller.markAllAsRead);
router.delete('/:id', controller.deleteNotification);

module.exports = router;