// Supports travel_time in both "HH:MM" (24-hour) and "hh:mm AM/PM" (12-hour) formats.
const to24Hour = (timeStr) => {
  if (!timeStr) return null;
  const trimmed = String(timeStr).trim();

  const ampmMatch = trimmed.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (ampmMatch) {
    let [, h, m, period] = ampmMatch;
    h = parseInt(h, 10);
    if (period.toUpperCase() === 'PM' && h !== 12) h += 12;
    if (period.toUpperCase() === 'AM' && h === 12) h = 0;
    return { hour: h, minute: parseInt(m, 10) };
  }

  const plainMatch = trimmed.match(/^(\d{1,2}):(\d{2})$/);
  if (plainMatch) {
    return { hour: parseInt(plainMatch[1], 10), minute: parseInt(plainMatch[2], 10) };
  }

  return null;
};

const classifyTimeSlot = (timeStr) => {
  const parsed = to24Hour(timeStr);
  if (!parsed) return 'normal';

  const { hour } = parsed;

  if (hour >= 5 && hour < 8) return 'early_morning';
  if (hour >= 8 && hour < 10) return 'morning_rush';
  if (hour >= 10 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 20) return 'evening_rush';
  return 'night';
};

module.exports = { classifyTimeSlot, to24Hour };
