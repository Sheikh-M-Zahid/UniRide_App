const getRemainingSeconds = (futureTime) => {
  if (!futureTime) return 0;

  const now = new Date();
  const end = new Date(futureTime);
  const diffMs = end - now;

  if (diffMs <= 0) return 0;
  return Math.floor(diffMs / 1000);
};

module.exports = {
  getRemainingSeconds,
};