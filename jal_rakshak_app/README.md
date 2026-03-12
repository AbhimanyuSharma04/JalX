# Jal-Rakshak Mobile App 📱

This is the Flutter Android application for the Jal-Rakshak platform.

## 🚀 Setup & Run

### Prerequisites
1.  **Flutter SDK** installed and in your PATH.
2.  **Android Studio** installed with Android SDK.
3.  **VS Code** (optional) with Flutter extension.
4.  **Android Device** connected via USB (Developer Mode & USB Debugging enabled).

### 1. Initialize Project
Since this code was generated, you need to fetch the dependencies and generate platform files.

Open your terminal in this directory (`jal_rakshak_app`) and run:

```bash
# Get dependencies
flutter pub get

# Generate Android/iOS folders (if missing)
flutter create .
```

### 2. Connect to Device
Connect your Android phone via USB.
Run `flutter devices` to verify it is detected.

### 3. Run the App
```bash
flutter run
```

### 4. Build APK for Android
To generate a release APK:
```bash
flutter build apk --release
```
The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## ⚙️ Environment Setup
The app uses constants defined in `lib/core/constants.dart`.
To change API keys or endpoints:
1.  Open `lib/core/constants.dart`.
2.  Update `supabaseUrl`, `supabaseAnonKey`, or `googleMapsApiKey`.
3.  Rebuild the app.

## 📂 Project Structure
-   `lib/core`: Constants, Theme, Router.
-   `lib/features`: Feature-based modules (Auth, Dashboard, Maps, etc.).
-   `lib/main.dart`: Entry point.

## 🔑 Key Features
-   **Authentication**: Login with Supabase.
-   **Dashboard**: Real-time sensor data & charts.
-   **Water Analysis**: Input parameters & Get AI Prediction.
-   **Outbreak Map**: Interactive Google Map.
-   **Community**: Health news & events.

## ⚠️ Troubleshooting
-   **"Target not found"**: Ensure your phone is connected and USB debugging is on.
-   **"MethodChannel" errors**: Stop the app and run `flutter clean` then `flutter run`.
-   **Map not showing**: Ensure the Google Maps API Key in `lib/core/constants.dart` is enabled for Android.
