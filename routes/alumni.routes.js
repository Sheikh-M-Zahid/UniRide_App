const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/authenticate');
const alumniController = require('../controllers/alumni.controller');
const { alumniUpload } = require('../utils/upload');

// REGISTER
router.post(
  '/register',
  authenticate,
  alumniUpload,
  alumniController.registerAlumni
);

// STATUS
router.get('/my-status', authenticate, alumniController.getMyStatus);

// UPDATE PROFILE
router.patch('/profile/update', authenticate, alumniController.updateProfile);

// LIST
router.get('/list', authenticate, alumniController.getAlumniList);

// DEPARTMENTS
router.get('/departments', authenticate, alumniController.getDepartments);

// CONTACT REQUEST
router.post('/contact-request', authenticate, alumniController.sendContactRequest);

// REQUESTS
router.get('/requests', authenticate, alumniController.getRequests);

// RESPOND
router.patch('/requests/:requestId/respond', authenticate, alumniController.respondRequest);

// CHAT
router.get('/chat/:sessionId/messages', authenticate, alumniController.getMessages);
router.get('/my-chats', authenticate, alumniController.getMyChats);

// ADMIN
router.get('/admin/pending', authenticate, alumniController.getPending);
router.get('/admin/count', authenticate, alumniController.getPendingCount);
router.patch('/admin/:alumniId/review', authenticate, alumniController.reviewAlumni);

module.exports = router;
