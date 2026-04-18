const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const rideRoutes = require('./routes/rideRoutes');
const rideChatRoutes = require('./routes/rideChatRoutes');
const ratingRoutes = require('./routes/ratingRoutes');
const companySharingRoutes = require('./routes/companySharingRoutes');
const liveLocationRoutes = require('./routes/liveLocationRoutes');
const sendItemRoutes = require('./routes/sendItemRoutes');
const offerRoutes = require('./routes/offerRoutes');
const reportRoutes = require('./routes/reportRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const adminRoutes = require('./routes/adminRoutes');
const homeRoutes = require('./routes/homeRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const walletRoutes = require('./routes/walletRoutes');
const supportRoutes = require('./routes/supportRoutes');
const reserveRoutes = require('./routes/reserveRoutes');
const activeRiderRoutes = require('./routes/activeRiderRoutes');
const earningsRoutes = require('./routes/earningsRoutes');
const activityRoutes = require('./routes/activityRoutes');
const riderActiveRideRoutes = require('./routes/riderActiveRideRoutes');
const riderDashboardRoutes = require('./routes/riderDashboardRoutes');
const passengerRideRequestRoutes = require('./routes/passengerRideRequestRoutes');
const riderRideHistoryRoutes = require('./routes/riderRideHistoryRoutes');
const riderMapRoutes = require('./routes/riderMapRoutes');
const riderProfileRoutes = require('./routes/riderProfileRoutes');
const riderSettingsRoutes = require('./routes/riderSettingsRoutes');
const confirmationRoutes = require('./routes/confirmationRoutes');
const riderVehicleSelectionRoutes = require('./routes/riderVehicleSelectionRoutes');
const riderBikeRoutes = require('./routes/riderBikeRoutes');
const riderCarRoutes = require('./routes/riderCarRoutes');
const adminDashboardRoutes = require('./routes/adminDashboardRoutes');
const adminPaymentApprovalRoutes = require('./routes/adminPaymentApprovalRoutes');
const adminProfileRoutes = require('./routes/adminProfileRoutes');
const adminReportsRoutes = require('./routes/adminReportsRoutes');
const adminPassengerRoutes = require('./routes/adminPassengerRoutes');
const adminRiderSharingHistoryRoutes = require('./routes/adminRiderSharingHistoryRoutes');
const adminSharingCaringHistoryRoutes = require('./routes/adminSharingCaringHistoryRoutes');
const adminTopLocationRoutes = require('./routes/adminTopLocationRoutes');
const appStatsRoutes = require('./routes/appStatsRoutes');
const rideOptionsRoutes = require('./routes/rideOptionsRoutes');
const rideAvailabilityAlertRoutes = require('./routes/rideAvailabilityAlertRoutes');
const helpRoutes = require('./routes/helpRoutes');
const riderDeliveryRoutes = require('./routes/riderDeliveryRoutes');
const activeRideSetupRoutes = require('./routes/activeRideSetupRoutes');
const securityRoutes = require('./routes/securityRoutes');
const privacyRoutes = require('./routes/privacyRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const mapsRoutes = require('./routes/mapsRoutes');
const rideRequestRoutes = require('./routes/rideRequestRoutes');

const errorMiddleware = require('./middlewares/errorMiddleware');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'UniRide backend is running.',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/ride-chat', rideChatRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/company-sharing', companySharingRoutes);
app.use('/api/live-locations', liveLocationRoutes);
app.use('/api/send-items', sendItemRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/rider/active-riders', activeRiderRoutes);
app.use('/api/reserve', reserveRoutes);
app.use('/api/rider/earnings', earningsRoutes);
app.use('/api/rider/activity', activityRoutes);
app.use('/api/rider/active-ride', riderActiveRideRoutes);
app.use('/api/rider/dashboard', riderDashboardRoutes);
app.use('/api/passenger/ride-requests', passengerRideRequestRoutes);
app.use('/api/rider/ride-history', riderRideHistoryRoutes);
app.use('/api/rider/map', riderMapRoutes);
app.use('/api/rider/profile', riderProfileRoutes);
app.use('/api/rider/settings', riderSettingsRoutes);
app.use('/api/confirmation', confirmationRoutes);
app.use('/api/rider/vehicle-selection', riderVehicleSelectionRoutes);
app.use('/api/rider/bike', riderBikeRoutes);
app.use('/api/rider/car', riderCarRoutes);
app.use('/api/admin/dashboard', adminDashboardRoutes);
app.use('/api/admin/payment-approvals', adminPaymentApprovalRoutes);
app.use('/api/admin/profile', adminProfileRoutes);
app.use('/api/admin/reports', adminReportsRoutes);
app.use('/api/admin/passengers', adminPassengerRoutes);
app.use('/api/admin/rider-sharing-history', adminRiderSharingHistoryRoutes);
app.use('/api/admin/sharing-caring-history', adminSharingCaringHistoryRoutes);
app.use('/api/admin/top-locations', adminTopLocationRoutes);
app.use('/api/admin/app-stats', appStatsRoutes);
app.use('/api/rides/options', rideOptionsRoutes);
app.use('/api/rides/notify-availability', rideAvailabilityAlertRoutes);
app.use('/api/help', helpRoutes);
app.use('/api/rider/delivery', riderDeliveryRoutes);
app.use('/api/active-ride', activeRideSetupRoutes);
app.use('/api/security', securityRoutes);
app.use('/api/privacy-data', privacyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/maps', mapsRoutes);
app.use('/api/ride-requests', rideRequestRoutes);

app.use(errorMiddleware);

module.exports = app;
