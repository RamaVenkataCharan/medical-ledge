import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medtrack_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://demo.invalid',
      // Keep this compatible with the Supabase key parameter used by this app.
      anonKey: 'local-test-anon-key', // ignore: deprecated_member_use
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MedTrackApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
