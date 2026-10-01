import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client singleton — initialized in main.dart via flutter_dotenv
SupabaseClient get supabase => Supabase.instance.client;
