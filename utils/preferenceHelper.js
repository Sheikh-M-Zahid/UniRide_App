const isValidGenderPreference = (value) => {
  // allow empty (optional field)
  if (value === null || value === undefined || value === '') {
    return true;
  }

  const allowed = ['male', 'female', 'any'];
  return allowed.includes(String(value).toLowerCase());
};

const isValidVehicleType = (value) => {
  if (!value) {
    return false;
  }

  const allowed = ['bike', 'car', 'seven_seater'];
  return allowed.includes(String(value).toLowerCase());
};

module.exports = {
  isValidGenderPreference,
  isValidVehicleType,
};