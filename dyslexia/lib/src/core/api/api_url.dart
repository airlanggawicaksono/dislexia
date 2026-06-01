class ApiUrl {
  const ApiUrl._();

  /// Compile-time default. Kept as a `const` so the rest of the app can
  /// still reach for `ApiUrl.baseUrl` from a `const` context (e.g. in a
  /// `const` widget tree) before [configure] has had a chance to run.
  static const _defaultBaseUrl = "https://dev.dyslexic.app/api/v1";

  /// Runtime override, set by [configure] at app start. When null we
  /// fall back to [_defaultBaseUrl] so the value never goes null.
  static String? _runtimeBaseUrl;

  /// The base URL the HTTP client should hit. Returns the runtime
  /// override if one was set, otherwise the compile-time default.
  static String get baseUrl => _runtimeBaseUrl ?? _defaultBaseUrl;

  /// Override the base URL at runtime. Call this once during app boot
  /// (e.g. from `main()`) before the DI container is built, so that
  /// the very first network call goes to the right host.
  ///
  /// Accepts an override from `String.fromEnvironment('API_BASE_URL')`
  /// or an explicit value for tests.
  static void configure({String? baseUrlOverride}) {
    if (baseUrlOverride != null && baseUrlOverride.isNotEmpty) {
      _runtimeBaseUrl = baseUrlOverride;
    }
  }

  static const usersBox = "users";
  static const productsBox = "products";
}
