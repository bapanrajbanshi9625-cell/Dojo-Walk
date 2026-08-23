# 🐾 Dojo Walk

**Dojo Walk** is a dog walking platform designed to connect pet owners with trusted dog walkers.

The app provides a simple and secure way for owners and walkers to manage walks, profiles, pets, QR connections, live walks and location tracking.

---

## 📱 App

**App Name:** Dojo Walk

**Platform:** Android

**Framework:** Flutter

**Backend:** Firebase

---

## ✨ Features

### 👤 Owner

- 📱 Mobile number OTP login
- 🆔 Automatic Owner ID generation
- 👤 Owner profile setup
- 🐶 Add and manage pets
- 🐕 Pet breed, age and behaviour
- 📍 GPS location
- 📷 Profile and pet photo support
- 🔳 Walker QR connection
- 🚶 Live Walk
- 🗺️ Live location tracking
- 📋 Walk history
- 📞 Phone/SMS support

### 🚶 Walker

- 📱 Mobile OTP authentication
- 👤 Walker profile
- 📷 Walker profile photo
- 🔳 QR scanner
- 🔍 Insta Walk search
- 📍 GPS location
- 🚶 Live Walk
- 🗺️ Live route tracking
- 🛑 Walk controls
- 📋 Walk history
- 🆘 SOS / support features

---

## 🔳 QR Connection

Dojo Walk uses QR-based owner/walker connection.

### Owner

1. Open Dojo Walk
2. Open **Scan QR Code**
3. QR code is generated
4. Walker scans the QR using the Walker app
5. Connection is detected automatically

### Walker

1. Open QR Scanner
2. Scan the Owner QR
3. Owner and Walker are connected
4. Live Walk can be started

---

## 🚶 Live Walk

Live Walk provides:

- Real-time location
- Route tracking
- Owner/Walker connection
- Walk status
- Start/Stop controls
- Walk history
- Safety features

---

## 🔥 Firebase

Dojo Walk uses Firebase services for backend functionality.

### Firebase Services

- Firebase Authentication
- Cloud Firestore
- Firebase Storage

### Main Firestore Collections

```text
ownerProfiles
phoneAccounts
walkers
walk_requests
active_walks
walk_history
