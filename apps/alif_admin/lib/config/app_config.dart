class AppConfig {
  AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment(
    'ALIF_API_BASE_URL',
    defaultValue: '',
  );

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
