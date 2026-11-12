# 📱 Attendly – Smart QR-Based Attendance Management System

A production-grade mobile application built with **Flutter**, **Clean Architecture**, **BLoC (Business Logic Component)**, **SQLite (Local Database)**, and **Mock REST APIs via Dio**. 

Attendly enables employees to mark their daily attendance securely by scanning dynamically generated, time-limited, and cryptographically signed QR codes, while capturing real-time GPS coordinates and timestamps.

---

## 🏛️ Application Architecture (Clean Architecture)

Attendly is designed following the principles of **Clean Architecture** and **Separation of Concerns**, ensuring high testability, modularity, and scalability:

```
lib/
├── core/                           # Application-wide singletons, utilities & contracts
│   ├── constants/app_constants.dart # Coordinates, session timers, secret keys, API paths
│   ├── errors/failures.dart        # Strongly-typed Failure objects (Equatable)
│   ├── network/dio_client.dart     # Dio HTTP client + MockDioInterceptor
│   ├── services/location_service.dart # GPS hardware integration (Geolocator)
│   └── utils/qr_crypto_helper.dart # HMAC-SHA256 signature generator & expiry validator
│
├── domain/                         # Pure Dart enterprise business logic (Zero external dependencies)
│   ├── entities/                   # Core business entities
│   │   ├── user_entity.dart        # User profile & role (Employee / Admin)
│   │   ├── attendance_entity.dart  # Attendance log model
│   │   └── qr_session_entity.dart  # Dynamic QR session model
│   └── repositories/               # Abstract repository contracts (Interfaces)
│       ├── auth_repository.dart
│       └── attendance_repository.dart
│
├── data/                           # Data manipulation & source implementations
│   ├── datasources/
│   │   ├── local/attendance_database.dart # SQLite local database helper (sqflite)
│   │   └── remote/mock_employee_data.dart # Dummy employee & admin credentials
│   ├── models/                     # Data models with JSON & SQLite Map serialization
│   │   ├── user_model.dart
│   │   └── attendance_model.dart
│   └── repositories/               # Concrete repository implementations
│       ├── auth_repository_impl.dart
│       └── attendance_repository_impl.dart
│
└── presentation/                   # UI & Reactive State Management (BLoC Only)
    ├── blocs/
    │   ├── auth/                   # AuthBloc, AuthEvent, AuthState
    │   ├── admin/                  # AdminBloc, AdminEvent, AdminState
    │   └── attendance/             # AttendanceBloc, AttendanceEvent, AttendanceState
    └── screens/
        ├── auth/login_screen.dart
        ├── admin/admin_dashboard_screen.dart
        └── employee/
            ├── employee_home_screen.dart
            ├── qr_scanner_screen.dart
            └── attendance_history_screen.dart
```

---

## 🛡️ Security & Anti-Fraud Architecture

To solve the **"Proxy Punch"** problem (where employees take pictures of QR codes and share them with friends), Attendly enforces a multi-layered security strategy:

1. **Time-Limited Dynamic QR Codes**: Each session QR code is strictly valid for **45 seconds**. A 1-second live countdown progress bar visualizes this, and on expiry, the session automatically regenerates.
2. **Cryptographic Tamper-Proofing (HMAC-SHA256)**: 
   - Payload: `{"sessionId":"...", "type":"CHECK_IN", "validFrom":..., "validUntil":..., "signature":"..."}`
   - The signature is calculated using a secret key. If an employee alters the JSON payload or the expiry timestamp, signature verification fails immediately (`QRTamperedFailure`).
3. **Duplicate Entry Enforcement**:
   - Check-In duplicate prevention: Employees cannot check in twice on the same calendar day.
   - Check-Out duplicate prevention: Employees cannot check out twice on the same day.
   - Sequence enforcement: Employees cannot check out without having checked in first.
4. **GPS Coordinate Capture**: Captures exact device latitude and longitude at the moment of scanning.
5. **Offline-First Synchronization**:
   - If network connectivity drops or the REST API is unreachable, records are safely cached in **SQLite** with `isSynced = 0`.
   - Users can sync pending offline records to the cloud with one tap once connection is restored.

---

## 👥 Dummy User Credentials

For testing and demonstration, the app includes pre-configured accounts:

| Role | Email | Password | Employee ID | Name |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | `admin@company.com` | `admin123` | `ADM001` | Robert Vance (Admin) |
| **Employee 1** | `john@company.com` | `password123` | `EMP001` | John Doe |
| **Employee 2** | `jane@company.com` | `password123` | `EMP002` | Jane Smith |
| **Employee 3** | `sarah@company.com` | `password123` | `EMP003` | Sarah Connor |

> 💡 *Tip: On the Login Screen, tap the quick test account chips (**"Employee (John)"** or **"Admin (Robert)"**) to auto-fill credentials instantly!*

---

## 🚀 Setup & Installation Instructions

### Prerequisites
- Flutter SDK `^3.12.0` or higher
- Android Studio / VS Code
- Android device or emulator with camera and location support

### 1. Clone the Repository
```bash
git clone https://github.com/AATHILA/attendly.git
cd attendly
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the Application
```bash
flutter run
```

---

## 🎥 Demonstration Video Walkthrough Script

When recording your demonstration video, follow this sequence:

1. **Authentication Flow (1 min)**:
   - Launch app on Login Screen.
   - Tap **"Employee (John)"** chip ➡️ Tap **Sign In**.
   - Show the Employee Portal displaying John Doe, ID `EMP001`, and status *"Not Checked In Yet"*.
2. **Admin Dynamic QR Session (1 min)**:
   - Log out, tap **"Admin (Robert)"** chip ➡️ Sign In.
   - Show the **Dynamic QR tab**: highlight the live 45s countdown timer bar.
   - Demonstrate automatic QR regeneration upon timer completion.
   - Switch between **Check-In** and **Check-Out** session types.
3. **Attendance Scanning & Validation (1.5 min)**:
   - Log back into Employee account on phone/emulator.
   - Tap **"Scan QR for Check-In"** ➡️ Scan the Admin QR code.
   - Show the success dialog capturing **Timestamp**, **GPS Coordinates**, and **Status**.
   - Return to portal: notice the Check-In button is now disabled with *"Already checked in today"*.
   - Try to scan Check-In again or scan an expired QR code to demonstrate the rejection alert!
4. **Attendance History & Offline Resilience (1 min)**:
   - Open **"Attendance Records & History"**: show the newly created record with GPS coordinates.
   - Return to Login Screen, toggle **"Simulate Network Offline"** switch.
   - Scan for Check-Out while offline ➡️ Show that it successfully saves locally to **SQLite** with the badge **"Offline Pending"**.
   - Tap **"Sync Now"** (after toggling offline off) to show it syncing to the cloud!
5. **Admin Attendance Logs (30 sec)**:
   - Switch back to Admin console ➡️ Open **"Attendance Logs"** tab to see all employee records, timestamps, and GPS coordinates listed.
