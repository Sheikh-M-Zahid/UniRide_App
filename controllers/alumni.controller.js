const alumniService = require('../services/alumni.service');
const alumniProfileService = require('../services/alumniProfile.service');

const handle = (res, fn) => fn().then(data => res.json(data)).catch(err => {
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Server error'
  });
});

exports.registerAlumni = (req, res) => handle(res, () => alumniService.registerAlumni(req));
exports.getMyStatus = (req, res) => handle(res, () => alumniService.getMyStatus(req));
exports.updateProfile = (req, res) => handle(res, () => alumniService.updateProfile(req));
exports.getAlumniList = (req, res) => handle(res, () => alumniService.getAlumniList(req));
exports.getDepartments = (req, res) => handle(res, () => alumniService.getDepartments());
exports.getAlumniProfile = (req, res) => handle(res, () => alumniProfileService.getAlumniProfileById(req));

exports.sendContactRequest = (req, res) => handle(res, () => alumniService.sendContactRequest(req));
exports.getRequests = (req, res) => handle(res, () => alumniService.getRequests(req));
exports.respondRequest = (req, res) => handle(res, () => alumniService.respondRequest(req));

exports.getMessages = (req, res) => handle(res, () => alumniService.getMessages(req));
exports.sendMessage = (req, res) => handle(res, () => alumniService.sendMessage(req));
exports.getMyChats = (req, res) => handle(res, () => alumniService.getMyChats(req));

// ADMIN
exports.getPending = (req, res) => handle(res, () => alumniService.getPending(req));
exports.getPendingCount = (req, res) => handle(res, () => alumniService.getPendingCount(req));
exports.reviewAlumni = (req, res) => handle(res, () => alumniService.reviewAlumni(req));
