const isValidUniversityEmail = (email) => {
  if (!email) return false;
  const normalized = email.trim().toLowerCase();
  return (
    normalized.endsWith('@std.ewubd.edu') ||
    normalized.endsWith('@ewubd.edu')
  );
};

const requireFields = (body, fields = []) => {
  const missing = [];

  for (const field of fields) {
    if (
      body[field] === undefined ||
      body[field] === null ||
      String(body[field]).trim() === ''
    ) {
      missing.push(field);
    }
  }

  return missing;
};

module.exports = {
  isValidUniversityEmail,
  requireFields,
};