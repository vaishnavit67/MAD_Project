# 🎓 Campus Connect — Integrated Smart Campus & Navigation Ecosystem

> **Course**: Mobile Application Development (23CSE465)  
> **Evaluation Window**: 13-10-2026 to 23-10-2026 | **Total Marks**: 25  
> **Tech Stack**: Flutter 3.x (Dart), Node.js (Express), MongoDB Atlas, Hive Local Storage, OpenStreetMap & Dijkstra Algorithm

---

## 📌 Project Overview

**Campus Connect** is an all-in-one mobile and web campus ecosystem engineered for university campuses (modeled on Amrita Vishwa Vidyapeetham, Coimbatore). It unifies:
1. **Interactive Campus Navigation & Routing**: Accurate pedestrian road routing using custom topological graphs, Dijkstra shortest path algorithms, and OSRM integration over OpenStreetMap and CORS-safe ESRI satellite imagery.
2. **Three-Tier Role-Based Architecture**: Strictly partitioned access for **Students**, **Faculty**, and **Visitors** with role-specific login validation, navigation restrictions, and dedicated dashboards.
3. **Clubs & Communities Hub**: Club discovery, faculty coordinator assignment, membership application lifecycle, message request notifications, and confetti celebration on membership approval.
4. **Events Hub & Attendance**: Capacity-managed event registrations, live seat counters, QR code verification, and cross-platform scheduling.
5. **Secure Lost & Found Vault**: Community lost/found reporting, ownership verification claims, finder-to-owner clipboard communication, and secure recipient-targeted notifications.
6. **Isolated Notification Engine**: Multi-recipient in-app inbox and native push notification delivery ensuring notifications reach only their intended targets without leaking across sessions.

---

## 🏗️ System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT APPLICATION                       │
│  (Cross-Platform: Android Mobile APK/AAB & Responsive Web App)         │
└──────────────────┬─────────────────────────────────┬───────────────────┘
                   │                                 │
                   ▼                                 ▼
      ┌─────────────────────────┐       ┌─────────────────────────┐
      │   Local Offline Cache   │       │  Topological Road Graph │
      │   (Hive Box Storage)    │       │  & Dijkstra Algorithms  │
      └─────────────────────────┘       └─────────────────────────┘
                   │
                   ▼ (REST API / JSON over HTTPS)
┌────────────────────────────────────────────────────────────────────────┐
│                     NODE.JS & EXPRESS BACKEND SERVER                   │
│   (Authentication, RBAC Middleware, File Uploads, Real-time Sync)       │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        MONGODB ATLAS CLOUD DATABASE                    │
│   Collections: students | faculty | visitors | locations |             │
│   lost_found | lost_found_claims | clubs | events | notifications      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Features by User Role

### 👨‍🎓 1. Student Experience
- **Authentication**: Secure domain validation restricted strictly to `@cb.students.amrita.edu` with 10-digit mobile number verification.
- **Academic Timetable & Tasks**: Interactive calendar, class reminders, and task completion checklists.
- **Club Applications**: Browse clubs, submit join requests to faculty coordinators, and receive celebration dialogs with confetti upon acceptance.
- **Event Booking**: One-tap event registration with instant seat reservation, cancellation options, and notification reminders.
- **Lost & Found**: Report lost possessions or browse found items with one-tap clipboard copy of the owner's contact number.

### 👩‍🏫 2. Faculty / Teacher Lead Experience
- **Department Partitioning**: Verified login requiring `@cb.amrita.edu` faculty domain.
- **Moderation Dashboard**: Live counters for total active clubs, hosted events, and pending student claim requests.
- **Club Management**: Review pending student join requests with one-tap "Approve" or "Decline", auto-dispatching notices to students.
- **Event Publishing**: Create and announce campus workshops and seminars with custom banners and venue assignments.
- **Security Claim Review**: Review proof-of-ownership verification claims and release resolved items to students.

### 🚶 3. Visitor / Guest Experience
- **Open Campus Access**: Consumer login with standard email providers (`@gmail.com`).
- **Campus Navigation**: Guided routing from Main Gate to public landmarks, auditoriums, guest parking, and administration reception.
- **Public Events**: Browse cultural fests, open seminars, and guest attractions with safety guidelines.

---

## 📦 Build Artifacts (Section F: APK & AAB)

Both release artifacts have been successfully built, signed, and verified in the repository:

### 1. Release APK (Android Package)
* **File Location**: `build/app/outputs/flutter-apk/app-release.apk`
* **Build Command**:
  ```bash
  flutter build apk --release
  ```
* **Installation via ADB**:
  ```bash
  adb install -r build/app/outputs/flutter-apk/app-release.apk
  ```

### 2. Signed Release AAB (Android App Bundle)
* **File Location**: `build/app/outputs/bundle/release/app-release.aab`
* **Build Command**:
  ```bash
  flutter build appbundle --release
  ```

### 3. Difference Between APK and AAB (Viva Reference)

| Feature | Android Package (APK) | Android App Bundle (AAB) |
|---|---|---|
| **Purpose** | Directly installable executable package on an Android device. | Publishing format uploaded to Google Play Console. |
| **Contents** | Contains compiled code and all resources for all screen densities, CPU ABIs (`arm64-v8a`, `armeabi-v7a`, `x86_64`), and languages. | Modular format containing base module and feature splits; not directly installable on devices without `bundletool`. |
| **Download Size** | Larger for end users because it includes redundant architecture and resolution assets. | **Up to 35% smaller** because Google Play's Dynamic Delivery generates optimized split APKs tailored to the user's device specs. |
| **Demo Usage** | Used for installing directly on evaluation devices via ADB or USB transfer. | Demonstrated during evaluation to prove production Google Play deployment readiness. |

---

## 🧪 Testing & Quality Assurance (Section G)

Comprehensive automated and manual testing is documented in **[`TESTING.md`](TESTING.md)**:

* **Automated Flutter Tests**: 47 passing tests (`flutter test`)
* **Backend Jest Tests**: 16 passing integration tests (`npx jest`)
* **Backend HTTP Suite**: 39 passing API tests (`node tests/lostFound.test.js`)
* **Total Passing Tests**: **102 Automated Tests (100% Success Rate)**

### Test Execution Commands:
```bash
# 1. Run Flutter unit & widget tests
flutter test

# 2. Run Backend integration tests
cd backend
npx jest tests/integrationRequirements.test.js --runInBand --forceExit

# 3. Run Lost & Found automated contract tests
cd backend
node tests/lostFound.test.js
```

---

## 📂 Folder Structure

```text
Campus Connect - MAD/
├── android/                         # Native Android configuration (Kotlin DSL gradle.kts)
├── backend/                         # Node.js Express Backend
│   ├── controllers/                 # Business logic (lostFoundController.js)
│   ├── middleware/                  # FirebaseAuth & JWT auth middleware
│   ├── models/                      # Mongoose schemas (Club, Event, LostFound, Notification)
│   ├── routes/                      # REST endpoints (auth, clubs, events, notifications, upload)
│   ├── tests/                       # Automated backend Jest & integration test suites
│   ├── server.js                    # Express application entrypoint
│   └── package.json                 # Backend dependencies & npm scripts
├── lib/                             # Flutter Client Source Code
│   ├── algorithms/                  # Dijkstra shortest path & campus topological graph
│   ├── core/                        # Design tokens, theme colors (LFColors, AppColors)
│   ├── features/
│   │   ├── notifications/           # In-app notification engine & local push service
│   │   └── tasks/                   # Task checklist & calendar features
│   ├── models/                      # Dart domain models (Event, Club, LostItem, POI)
│   ├── screens/
│   │   ├── auth/                    # Role-partitioned Login & Signup screens
│   │   ├── clubs/                   # Club hub, application modal, teacher review
│   │   ├── events/                  # Event registration, capacity counters, QR scanner
│   │   ├── lost_found/              # Lost & Found listings, claims, and verified return
│   │   ├── home/                    # Home screen with personalized greeting & announcements
│   │   └── navigation/              # Interactive OpenStreetMap & navigation view
│   ├── services/                    # AuthService, MongoDBService, MapConfigService, ClubService
│   └── main.dart                    # Application bootstrap & route declarations
├── test/                            # Flutter automated unit, widget, and algorithm tests
├── TESTING.md                       # Complete 25-mark QA & testing report (Section G)
├── pubspec.yaml                     # Flutter dependencies and assets
└── README.md                        # Documentation & evaluation manual (Section H)
```

---

## 🛠️ Getting Started & Installation

### Prerequisites
* Flutter SDK (v3.24.0 or higher)
* Node.js (v18 or higher) and npm
* Android Device or Emulator (Android 8.0+, API 26+)
* Active Internet connection for MongoDB Atlas access

### 1. Backend Server Setup
```bash
cd backend
npm install
npm start
```
*The server will start on `http://localhost:5000` with active connection to MongoDB database `test`.*

### 2. Flutter Mobile Application Setup
```bash
# From workspace root
flutter pub get
flutter run
```

### 3. Running as Web Application (Section I2)
```bash
flutter run -d chrome
```

---

## 👥 Team & Module Distribution (Section H2 / J1)

| Module / Component | Lead Contributor | Key Screens & Responsibilities |
|---|---|---|
| **Authentication & Database Security** | Team Member 1 | Partitioned auth screens, domain validators, JWT middleware, MongoDB collections. |
| **Navigation & Topological Algorithms** | Team Member 2 | Dijkstra shortest path, OpenStreetMap polylines, pedestrian turn maneuvers. |
| **Clubs Hub & Faculty Moderation** | Team Member 3 | Club discovery, student applications, teacher review, confetti celebration. |
| **Events & Notifications System** | Team Member 4 | Event registration, capacity tracking, QR scanning, recipient-isolated in-app inbox. |
| **Lost & Found & Build Pipeline** | Team Member 5 | Item listing, ownership verification claims, release APK & signed AAB pipeline. |
