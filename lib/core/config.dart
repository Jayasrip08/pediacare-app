/// Build-time configuration, injected with --dart-define / --dart-define-from-file.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Private Supabase Storage bucket (see migration).
  static const storageBucket = 'child-files';

  /// Payload prefix encoded in the clinic QR code.
  static const clinicQrPrefix = 'PEDIACARE:';

  static const supportEmail = 'innoliftventures@gmail.com';
}
