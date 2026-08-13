const alumniCallService = require('../services/alumniCall.service');

const handle = (res, fn) => fn().then(data => res.json(data)).catch(err => {
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Server error'
  });
});

exports.requestCallPermission = (req, res) => handle(res, () => alumniCallService.requestCallPermission(req));
exports.respondCallPermission = (req, res) => handle(res, () => alumniCallService.respondCallPermission(req));
exports.getCallPermissionStatus = (req, res) => handle(res, () => alumniCallService.getCallPermissionStatus(req));
