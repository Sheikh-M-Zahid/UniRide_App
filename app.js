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
const riderOfferRoutes = require('./routes/riderOfferRoutes');
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
const riderVehicleRoutes = require('./routes/riderVehicleRoutes');
const riderVerificationRoutes = require('./routes/riderVerificationRoutes');
const adminVehicleRoutes = require('./routes/adminVehicleRoutes');
const adminDashboardRoutes = require('./routes/adminDashboardRoutes');
const adminPaymentApprovalRoutes = require('./routes/adminPaymentApprovalRoutes');
const adminProfileRoutes = require('./routes/adminProfileRoutes');
const adminReportsRoutes = require('./routes/adminReportsRoutes');
const adminPassengerRoutes = require('./routes/adminPassengerRoutes');
const adminRiderRoutes = require('./routes/adminRiderRoutes');
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
const safetyCheckRoutes = require('./routes/safetyCheckRoutes');
const adminSafetyRoutes = require('./routes/adminSafetyRoutes');
const sosRoutes = require('./routes/sosRoutes');
const mapsRoutes = require('./routes/mapsRoutes');
const rideRequestRoutes = require('./routes/rideRequestRoutes');
const profileRoutes = require('./routes/profileRoutes');
const savedPlaceRoutes = require('./routes/savedPlacesRoutes');
const rideHistoryRoutes = require('./routes/rideHistoryRoutes');
const fareRoutes = require('./routes/fareRoutes');
const alumniRoutes = require('./routes/alumni.routes');
const errorMiddleware = require('./middlewares/errorMiddleware');
const checkSuspension = require('./middlewares/checkSuspension');

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

app.get('/api/track/send-item/:sId', (req, res) => {
  const { sId } = req.params;
  res.status(200).send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Track Delivery — UniRide</title>
      <style>
        body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f9fafb; }
        .card { background: white; border-radius: 16px; padding: 40px 32px; max-width: 400px; width: 90%; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        h2 { color: #14B8A6; margin-bottom: 8px; }
        p { color: #6b7280; line-height: 1.6; }
        .badge { background: #e6fffa; color: #0f766e; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; display: inline-block; margin-bottom: 20px; }
        .id { background: #f3f4f6; padding: 10px 16px; border-radius: 8px; font-family: monospace; color: #374151; font-size: 13px; margin: 16px 0; word-break: break-all; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="badge">📦 Live Tracking</div>
        <h2>UniRide Delivery</h2>
        <p>To track your delivery in real-time, please open the <strong>UniRide app</strong>.</p>
        <div class="id">Tracking ID: ${sId}</div>
        <p style="font-size: 13px; color: #9ca3af;">Open the app → My Deliveries → Enter tracking ID</p>
      </div>
    </body>
    </html>
  `);
});

app.use(checkSuspension);

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/ride-chat', rideChatRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/company-sharing', companySharingRoutes);
app.use('/api/live-locations', liveLocationRoutes);
app.use('/api/send-items', sendItemRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/rider/offers', riderOfferRoutes);
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
app.use('/api/rider/vehicles', riderVehicleRoutes);
app.use('/api/rider-verification', riderVerificationRoutes);
app.use('/api/admin/vehicles', adminVehicleRoutes);
app.use('/api/admin/dashboard', adminDashboardRoutes);
app.use('/api/admin/payment-approvals', adminPaymentApprovalRoutes);
app.use('/api/admin/profile', adminProfileRoutes);
app.use('/api/admin/reports', adminReportsRoutes);
app.use('/api/admin/passengers', adminPassengerRoutes);
app.use('/api/admin/riders', adminRiderRoutes);
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
app.use('/api/safety-checks', safetyCheckRoutes);
app.use('/api/admin/safety-checks', adminSafetyRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/maps', mapsRoutes);
app.use('/api/ride-requests', rideRequestRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api', savedPlaceRoutes);
app.use('/api', rideHistoryRoutes);
app.use('/api/admin', fareRoutes);
app.use('/api/fare', fareRoutes);
app.use('/api/alumni', alumniRoutes);

app.use(errorMiddleware);

module.exports = app;
