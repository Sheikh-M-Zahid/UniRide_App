const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/authMiddleware');
const alumniController = require('../controllers/alumni.controller');
const { alumniUpload } = require('../utils/upload');

router.post('/register', authenticate, alumniUpload, alumniController.registerAlumni);
router.get('/my-status', authenticate, alumniController.getMyStatus);
router.patch('/profile/update', authenticate, alumniController.updateProfile);
router.get('/list', authenticate, alumniController.getAlumniList);
router.get('/departments', authenticate, alumniController.getDepartments);

router.post('/contact-request', authenticate, alumniController.sendContactRequest);
router.get('/requests', authenticate, alumniController.getRequests);
router.patch('/requests/:requestId/respond', authenticate, alumniController.respondRequest);

router.get('/chat/:sessionId/messages', authenticate, alumniController.getMessages);
router.get('/my-chats', authenticate, alumniController.getMyChats);

// Public alumni profile view — এটা সব লিটারেল রুটের (list, departments, requests, my-chats ইত্যাদি)
// নিচে রাখা বাধ্যতামূলক, নাহলে Express '/alumni/departments' কে alumniId ধরে ফেলবে
router.get('/:alumniId', authenticate, alumniController.getAlumniProfile);

// ADMIN
router.get('/admin/pending', authenticate, alumniController.getPending);
router.get('/admin/count', authenticate, alumniController.getPendingCount);
router.patch('/admin/:alumniId/review', authenticate, alumniController.reviewAlumni);

module.exports = router;
