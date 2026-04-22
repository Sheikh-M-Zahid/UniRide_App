const express = require('express');
const router = express.Router();

const sendItemController = require('../controllers/sendItemController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/validate-receiver',
  authMiddleware,
  sendItemController.validateReceiver
);

router.post(
  '/',
  authMiddleware,
  validateRequiredFields([
    'receiver_email',
    'item_type',
    'item_weight',
    'sender_name',
    'sender_phone',
    'pickup_location',
    'destination_location',
    'pickup_lat',
    'pickup_lng',
    'destination_lat',
    'destination_lng',
  ]),
  sendItemController.createSendItemRequest
);

router.get('/available', authMiddleware, sendItemController.getAvailableSendItemRequests);
router.get('/my-sent', authMiddleware, sendItemController.getMySentItems);
router.get('/my-rides', authMiddleware, sendItemController.getMyRiderSendItems);

router.get('/:sId', authMiddleware, sendItemController.getSenderItemDetails);
router.get('/:sId/sender-details', authMiddleware, sendItemController.getSenderItemDetails);
router.get('/:sId/rider-details', authMiddleware, sendItemController.getRiderItemDetails);

router.patch('/:sId/accept', authMiddleware, sendItemController.acceptItemRequest);
router.patch('/:sId/pickup', authMiddleware, sendItemController.pickupItemRequest);
router.patch('/:sId/deliver', authMiddleware, sendItemController.deliverItemRequest);
router.patch('/:sId/cancel', authMiddleware, sendItemController.cancelItemRequest);

module.exports = router;
