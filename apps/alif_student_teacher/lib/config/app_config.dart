class AppConfig {
  AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment(
    'ALIF_API_BASE_URL',
    defaultValue: '',
  );
  static const String _supabaseUrl = String.fromEnvironment(
    'ALIF_SUPABASE_URL',
    defaultValue: '',
  );
  static const String _supabasePublishableKey = String.fromEnvironment(
    'ALIF_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl {
    if (_supabaseUrl.isEmpty) {
      throw StateError(
        'Missing ALIF_SUPABASE_URL. Run with --dart-define-from-file=env/dev.json',
      );
    }
    return _supabaseUrl;
  }

  static String get supabasePublishableKey {
    if (_supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing ALIF_SUPABASE_PUBLISHABLE_KEY. Run with --dart-define-from-file=env/dev.json',
      );
    }
    return _supabasePublishableKey;
  }

  static Uri apiUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    if (_apiBaseUrl.isEmpty) {
      throw StateError(
        'Missing ALIF_API_BASE_URL. Run with --dart-define=ALIF_API_BASE_URL=<api-url>',
      );
    }

    final normalizedBase = _apiBaseUrl.endsWith('/')
        ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1)
        : _apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters:
          queryParameters == null || queryParameters.isEmpty
              ? null
              : queryParameters,
    );
  }
}
