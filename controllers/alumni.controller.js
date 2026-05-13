const alumniService = require('../services/alumni.service');

exports.registerAlumni = async (req, res) => {
  try {
    const result = await alumniService.registerAlumni(req);
    res.status(201).json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getMyStatus = async (req, res) => {
  try {
    const result = await alumniService.getMyStatus(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const result = await alumniService.updateProfile(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getAlumniList = async (req, res) => {
  try {
    const result = await alumniService.getAlumniList(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getDepartments = async (req, res) => {
  try {
    const result = await alumniService.getDepartments();
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.sendContactRequest = async (req, res) => {
  try {
    const result = await alumniService.sendContactRequest(req);
    res.status(201).json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getRequests = async (req, res) => {
  try {
    const result = await alumniService.getRequests(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.respondRequest = async (req, res) => {
  try {
    const result = await alumniService.respondRequest(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getMessages = async (req, res) => {
  try {
    const result = await alumniService.getMessages(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getMyChats = async (req, res) => {
  try {
    const result = await alumniService.getMyChats(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

// ADMIN
exports.getPending = async (req, res) => {
  try {
    const result = await alumniService.getPending(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.getPendingCount = async (req, res) => {
  try {
    const result = await alumniService.getPendingCount(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

exports.reviewAlumni = async (req, res) => {
  try {
    const result = await alumniService.reviewAlumni(req);
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
};

// Common error handler
const handleError = (res, err) => {
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Server error',
  });
};
