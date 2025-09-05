class AppConfig {
  static const githubUsername = String.fromEnvironment(
    'GITHUB_USERNAME',
    // FIXED: Corrected the default fallback value
    defaultValue: 'RHineIx',
  );

  static const githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    // FIXED: Corrected the default fallback value
    defaultValue: 'key',
  );

  static const githubToken = String.fromEnvironment(
    'GITHUB_TOKEN',
    // FIXED: Using the token you provided as the default fallback
    defaultValue: 'ghp_',
  );
}