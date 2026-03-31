const isValidDate = (dateString) => {
  const date = new Date(dateString);
  return !isNaN(date.getTime());
};

const isValidTime = (timeString) => {
  return /^(0?[1-9]|1[0-2]):[0-5][0-9]\s?(AM|PM)$/i.test(timeString);
};

const isPastDate = (dateString) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const selected = new Date(dateString);
  selected.setHours(0, 0, 0, 0);

  return selected < today;
};

const isBeyondLimit = (dateString, daysLimit = 90) => {
  const today = new Date();
  const maxDate = new Date();
  maxDate.setDate(today.getDate() + daysLimit);

  const selected = new Date(dateString);

  return selected > maxDate;
};

module.exports = {
  isValidDate,
  isValidTime,
  isPastDate,
  isBeyondLimit,
};