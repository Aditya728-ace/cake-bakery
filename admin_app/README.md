# Bakery Studio (Flutter admin app)

Requires Flutter 3.27+ (Dart 3.3+). Talks only to the backend API; it contains no database or storage credentials.

## First-time setup
```bash
cd admin_app
flutter create . --org com.yourbakery --project-name bakery_admin   # generates android/ ios/ (keeps lib/ and pubspec.yaml)
rm -f test/widget_test.dart                                         # the generated sample test references a different app
flutter pub get
```

### Android (`android/app/src/main/AndroidManifest.xml`)
Add inside `<manifest>` (above `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
For local testing against `http://` (emulator/LAN) also add `android:usesCleartextTraffic="true"` to `<application>`; **remove it for release**, where the API is HTTPS.
In `android/app/build.gradle(.kts)` set `minSdk = 23` (needed by flutter_secure_storage).

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key><string>Take photos of your cakes.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Choose cake photos from your gallery.</string>
```

## Run
```bash
# Android emulator + backend on your computer (default URL is http://10.0.2.2:8000)
flutter run
# Real phone on the same Wi-Fi
flutter run --dart-define=API_URL=http://192.168.x.x:8000
# Against your deployed backend
flutter run --dart-define=API_URL=https://your-api.onrender.com
```

## Release build
```bash
flutter build apk --release --dart-define=API_URL=https://your-api.onrender.com   # install the APK directly
flutter build appbundle --release --dart-define=API_URL=...                       # Google Play
```
Signing: https://docs.flutter.dev/deployment/android#signing-the-app

## Using the app
1. **First launch:** tap "Create the owner account" (needs `ADMIN_INVITE_CODE` if the backend sets one). Registration closes after the owner exists.
2. **Bakery tab:** logo, name, contact, WhatsApp number (digits with country code), social links.
3. **Website tab:** headline, story, announcement bar, homepage photo.
4. **Cakes tab:** "New cake" → add photos (camera/gallery) → Preview → Save & publish. The switch on each cake publishes/unpublishes instantly.
