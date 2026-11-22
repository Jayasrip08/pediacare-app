/// Build-time configuration, injected with --dart-define / --dart-define-from-file.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ulvhvhlolipqvdaqypxo.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsdmh2aGxvbGlwcXZkYXF5cHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUwMDQ1MzgsImV4cCI6MjExMDU4MDUzOH0.EGwlit3skI7iRHKErL11grgUfLJoKL7Ul_inoWX4faY',
  );

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Private Supabase Storage bucket (see migration).
  static const storageBucket = 'child-files';

  /// Payload prefix encoded in the clinic QR code.
  static const clinicQrPrefix = 'PEDIACARE:';

  static const supportEmail = 'innoliftventures@gmail.com';
}
