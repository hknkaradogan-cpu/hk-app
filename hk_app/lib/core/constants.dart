class AppConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const List<String> taskStatuses = ['BEKLIYOR', 'YAPILDI', 'DND', 'RED'];
  static const List<String> taskTypes = ['checkout', 'stayover', 'arrival'];
  static const List<String> roles = ['supervisor', 'maid'];
}
