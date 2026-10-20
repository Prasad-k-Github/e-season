import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_season/screens/dashboard_screen.dart';
import 'package:e_season/services/profile_repository.dart';
import 'package:e_season/services/session_store.dart';
import 'package:e_season/utils/app_strings.dart';

Future<void> _pump(WidgetTester tester, ProfileRepository repo,
    {String? token = 't'}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(MaterialApp(
    routes: {'/login': (_) => const Text('LOGIN PAGE')},
    home: DashboardScreen(repo: repo, session: MemorySessionStore()..token = token),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('verified passenger sees their name and the apply action', (tester) async {
    await _pump(tester, const MockProfileRepository());
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text(AppStrings.applySeasonAction), findsOneWidget);
    expect(find.text(AppStrings.dashPendingTitle), findsNothing);
  });

  testWidgets('unverified passenger sees the waiting message on every tab', (tester) async {
    await _pump(tester, const MockProfileRepository(status: 'pending_verification'));
    expect(find.text(AppStrings.dashPendingTitle), findsOneWidget);
    expect(find.text(AppStrings.applySeasonAction), findsNothing);

    await tester.tap(find.text('My Pass'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.dashPendingTitle), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.dashPendingTitle), findsOneWidget);
  });

  testWidgets('government accounts show the institution message', (tester) async {
    await _pump(tester, const MockProfileRepository(status: 'pending_institution_approval'));
    expect(find.text(AppStrings.dashInstitutionTitle), findsOneWidget);
  });

  testWidgets('no session goes back to login', (tester) async {
    await _pump(tester, const MockProfileRepository(), token: null);
    expect(find.text('LOGIN PAGE'), findsOneWidget);
  });
}
