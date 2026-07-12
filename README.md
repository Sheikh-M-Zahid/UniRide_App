# UniRide_App
# 🛵 UniRide — Campus Ride Sharing & Delivery App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat&logo=node.js&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)

A complete ride sharing and delivery platform built for the students of East West University (EWU) campus.

## ✨ Features

- Standard ride booking (passenger ↔ rider)
- CoRide — gender-based carpooling with real-time seat availability
- Send Item — parcel delivery with OTP confirmation
- Live GPS tracking with Google Maps + polylines
- Push notifications via Firebase FCM
- Promo codes & fare management (admin)
- Wallet & earnings dashboard
- Email OTP via Brevo API

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Node.js / Express |
| Database | PostgreSQL (Neon) |
| Auth & Push | Firebase (FCM) |
| Real-time | Socket.IO |
| Maps | Google Maps SDK + Directions API |
| Email | Brevo HTTP API |
| Deployment | Render (backend) |

## 📁 Project Structure

```
UniRide_App/
├── lib/               # Flutter frontend
│   ├── screens/       # UI pages
│   ├── services/      # API & Firebase services
│   └── main.dart
├── backend/           # Node.js backend
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   └── server.js
└── README.md
```

## 🚀 Getting Started

**Backend:**
```bash
cd backend
npm install
cp .env.example .env   # Fill in your credentials
node server.js
```

**Flutter:**
```bash
flutter pub get
flutter run
```

## 👤 Developer

Md. Zahid Hossain, Marjan Hasan, Marzia Hasan — East West University, Bangladesh
