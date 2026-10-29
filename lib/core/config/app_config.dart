class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dy.solvyngroups.com/api/v1',
  );

  static bool get isApiConfigured => apiBaseUrl.trim().isNotEmpty;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String visitorsPath = '/visitors';
}
