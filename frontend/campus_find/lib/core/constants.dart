/// Central, non-secret configuration for the CampusFind Flutter app.
///
/// The backend base URL is the ONLY configurable value here and it contains no
/// secrets. Override it at build/run time with `--dart-define`, for example:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
///
/// Defaults below:
///  - Android emulator reaches the host machine via 10.0.2.2
///  - iOS simulator / desktop use localhost
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const String appName = 'CampusFind';

  static const List<String> itemCategories = [
    'electronics',
    'documents',
    'clothing',
    'accessories',
    'books',
    'keys',
    'wallet',
    'bags',
    'jewelry',
    'sports',
    'other',
  ];
}
