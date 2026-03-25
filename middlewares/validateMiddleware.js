const { errorResponse } = require('../utils/apiResponse');
const { requireFields } = require('../utils/validators');

const validateRequiredFields = (fields = []) => {
  return (req, res, next) => {
    const missing = requireFields(req.body, fields);

    if (missing.length > 0) {
      return errorResponse(
        res,
        `Missing required fields: ${missing.join(', ')}`,
        400
      );
    }

    next();
  };
};

module.exports = {
  validateRequiredFields,
};