# DrugScript

DrugScript is a Flutter healthcare app for managing digital prescriptions. Patients and doctors can create prescriptions, share them by QR code, search for medicines, set medication reminders, and review doctors and clinics. The app also includes early-stage screens for medicine delivery and ambulance booking.

The app uses **Firebase Authentication** (Google Sign-In) for login and a REST backend hosted on Azure (`https://drugscript.azurewebsites.net`) for data.

---

## Features

| Feature | Description | Screen(s) |
|---|---|---|
| **Google Sign-In** | Firebase Auth with Google. After login, the app syncs the user's profile with the backend. | `login.dart`, `wrapper.dart` |
| **Profile** | Create, edit and delete a user profile (blood type, gender, etc.). Public profiles can be viewed by other users. | `profile.dart` |
| **Medicine Search** | Search the medicine database and view details for each medicine. | `medicine_search.dart`, `patient_medicine_search.dart`, `medicine_detail.dart`, `medicineCategoryPage.dart` |
| **Add Prescription** | Write a prescription with diagnosis, medicines and an optional image. | `add_prescription.dart` |
| **View Prescriptions** | List your prescriptions, open details, and show a QR code for each one. | `view_prescriptions.dart`, `prescription_details.dart` |
| **Scan QR** | Scan another user's prescription QR code to receive it. | `scan_qr_page.dart` |
| **Sharing History** | See prescriptions you have sent and received. | `sharing_history.dart` |
| **My Reports** | Attach medical report images from the camera or gallery. | `report.dart` |
| **Reminders** | Medication reminders using local notifications, saved on the device. | `reminder_page.dart` |
| **Community Chat** | A shared chat room for all users. | `chat_page.dart` |
| **Reviews** | Browse top doctors and clinics, search clinics, and post reviews. | `review_page.dart` |
| **Medicine Delivery** *(UI prototype)* | Separate views for patients, pharmacies and delivery riders. | `medicine_delivery_*.dart`, `medicineDelivery.dart` |
| **Ambulance Services** *(UI prototype)* | Patient and driver views with Google Maps and location picking. | `ambulance_*.dart`, `location_picker_page.dart`, `address_picker_page.dart` |

> Medicine Delivery and Ambulance Services are UI only for now. They do not call the backend yet.

---

## Tech Stack

- **Flutter / Dart** (SDK `>=3.8.0 <4.0.0`)
- **Firebase**: `firebase_core`, `firebase_auth`, `google_sign_in`
- **Navigation**: `get` (`GetMaterialApp`) with named routes
- **Networking**: `http`
- **Local storage**: `shared_preferences`
- **QR codes**: `qr_flutter` (generate), `mobile_scanner` (scan)
- **Notifications**: `flutter_local_notifications`, `timezone`
- **Maps and location**: `google_maps_flutter`, `geolocator`, `geocoding`, `location`, Google Places API
- **UI**: `flutter_svg`, `shimmer`, `lottie`, `fl_chart`, `flutter_rating_bar`, `flutter_slidable`, `dropdown_search`, `pinput`, `intl_phone_field`, `cached_network_image`

---

## Project Structure

```
lib/
├── main.dart               # App entry: Firebase init, notifications, routes
├── models/                 # Data models (user, prescription, medicine, clinic, review, cart, delivery, ambulance)
├── screens/                # All UI pages (see Features table)
├── services/
│   ├── ServerBaseURL.dart  # Backend base URL (ServerConfig.baseUrl)
│   ├── api_service.dart    # Profile, medicine search, prescription API calls
│   ├── auth_service.dart   # Google Sign-In / Firebase Auth / ID tokens
│   ├── chat_service.dart   # Community chat API
│   ├── medicine_search_service.dart
│   └── storage_service.dart
├── theme/app_theme.dart    # App-wide light theme
└── utils/                  # Constants, helpers, form validators
assets/                     # Logos, Google icon, OTP illustration
```

### App flow

```
SplashScreen ('/') → Wrapper ('/wrapper')
                       ├── signed in  → HomePage
                       └── signed out → Login (Google Sign-In)
```

`HomePage` is a dashboard of feature tiles that link to the routes defined in `main.dart`.

---

## Backend API

The base URL is set in [`lib/services/ServerBaseURL.dart`](lib/services/ServerBaseURL.dart):

```dart
class ServerConfig {
  static const String baseUrl = "https://drugscript.azurewebsites.net";
}
```

Requests are authenticated with the user's Firebase ID token. The app uses these endpoints:

| Endpoint | Used for |
|---|---|
| `/profile`, `/profile/auth-login`, `/profile/public/{userId}` | User profile and login sync |
| `/medicinesearch` | Medicine search |
| `/add_prescription`, `/prescriptions` | Create and list prescriptions |
| `/recievedPrescription`, `/sentPrescriptions` | Prescription sharing (QR) and history |
| `/messages/`, `/messages/latest` | Community chat |
| `/reviews`, `/doctors/top`, `/clinics/top`, `/clinics/_search` | Reviews for doctors and clinics |

To use a local or different backend, change `baseUrl`.

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart 3.8 or later)
- Android Studio or Xcode, plus a device or emulator
- A Firebase project with **Google Sign-In** enabled
- A Google Maps / Places API key (for the map features)

### Setup

1. **Clone and install packages**
   ```bash
   git clone <repo-url>
   cd DrugScript
   flutter clean
   flutter pub get
   ```

2. **Firebase**
   - Android: put `google-services.json` in `android/app/`.
   - iOS: put `GoogleService-Info.plist` in `ios/Runner/`.
   - Add your debug and release SHA-1 fingerprints in the Firebase console so Google Sign-In works on Android.

3. **Google Maps**
   - Set your key in `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`).
   - The Places key used in `address_picker_page.dart` and `ambulance_patient_side.dart` must also be valid.

4. **Run**
   ```bash
   flutter run
   ```

### Other commands

```bash
flutter analyze                                # Static analysis (flutter_lints)
flutter test                                   # Run tests
flutter build apk --release                    # Android release build
dart run flutter_launcher_icons                # Regenerate app icons from assets/logo.png
```

---

## Permissions

The app asks for the following at runtime:

- **Camera**: scanning QR codes and taking prescription or report photos
- **Photos / storage**: picking images from the gallery
- **Location**: ambulance and delivery address picking
- **Notifications**: medication reminders

---

## Notes

- The app currently only sets up Android notifications (`AndroidInitializationSettings` in `main.dart`). iOS notification setup still needs to be added.
- Some files are placeholders or older versions, for example `lib/theme/DELETEMELATER`, `lib/widgets/DELETEMELATER` and `ambulance_services_page_clean.dart`.
