class AppConfig {
  static const githubUsername = String.fromEnvironment(
    'GITHUB_USERNAME',
    // FIXED: Corrected the default fallback value
    defaultValue: '',
  );

  static const githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    // FIXED: Corrected the default fallback value
    defaultValue: '',
  );

  static const githubToken = String.fromEnvironment(
    'GITHUB_TOKEN',
    // FIXED: Using the token you provided as the default fallback
    defaultValue: '',
  );
}