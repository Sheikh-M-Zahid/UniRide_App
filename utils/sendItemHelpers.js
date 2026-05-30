const { isValidUniversityEmail } = require('./validators');

const calculateDeliveryFee = (weight) => {
  const w = Number(weight);

  if (!w || w <= 0) return 50;
  if (w <= 2) return 50;
  return 50 + Math.ceil(w - 2) * 10;
};

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const isPendingStatus = (status) => String(status || '').toLowerCase() === 'pending';
const isAcceptedStatus = (status) => String(status || '').toLowerCase() === 'accepted';
const isPickedUpStatus = (status) => String(status || '').toLowerCase() === 'picked_up';

const canCancelSendItem = (status) => {
  const normalized = String(status || '').toLowerCase();
  return normalized === 'pending' || normalized === 'accepted';
};

const canAcceptSendItem = (status) => isPendingStatus(status);
const canPickupSendItem = (status) => isAcceptedStatus(status);
const canDeliverSendItem = (status) => isPickedUpStatus(status);

const validateReceiverEmailInput = (receiverEmail) => {
  if (!receiverEmail || !String(receiverEmail).trim()) {
    throw new Error('Receiver email is required.');
  }

  const normalizedEmail = normalizeEmail(receiverEmail);

  if (!isValidUniversityEmail(normalizedEmail)) {
    throw new Error('Enter a valid university email.');
  }

  return normalizedEmail;
};

module.exports = {
  calculateDeliveryFee,
  normalizeEmail,
  canCancelSendItem,
  canAcceptSendItem,
  canPickupSendItem,
  canDeliverSendItem,
  validateReceiverEmailInput,
};
