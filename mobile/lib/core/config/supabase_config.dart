/// Supabase project configuration.
///
/// Replace the placeholder values below with your actual Supabase project
/// credentials from: https://supabase.com/dashboard → Project Settings → API.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL.
  /// Example: 'https://xyzcompany.supabase.co'
  // TODO: INSERT YOUR SUPABASE PROJECT URL
  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ptlzpwfrrxfqfprkvbuf.supabase.co',
  );

  /// Your Supabase publishable (anonymous) key.
  /// This is safe to expose in client-side code.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_EejIRNDd-fW5B60sgLKtWA_n5VQWwKt',
  );
}
