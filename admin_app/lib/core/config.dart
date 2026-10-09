/// Backend URL. Override at build time:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000
///   flutter build apk --release --dart-define=API_URL=https://your-api.onrender.com
/// 10.0.2.2 is the host machine as seen from the Android emulator.
const String apiBase = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
