import 'package:atom/config/app_theme.dart';
import 'package:atom/controllers/theme_controller.dart';
import 'package:atom/controllers/user_data_controller.dart';
import 'package:atom/models/user_model.dart';
import 'package:atom/views/settings/account_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for [UserProfileController] so the screens never hit the network.
class FakeUserProfileController extends UserProfileController {
  int fetchCount = 0;

  @override
  Future<void> fetchUserProfile() async => fetchCount++;
}

UserModel _sampleUser() => UserModel.fromJson({
  'id': 1,
  'userId': 'u-123',
  'fullName': 'Jane Wanjiku Doe',
  'phoneNumber': '+254 712 345 678',
  'emailAddress': 'jane.doe@atomiot.live',
  'userRole': 'Admin',
  'profileImage': '',
  'userActive': true,
  'createdAt': '2024-03-11T08:30:00Z',
  'lastLogin': '2026-07-16T19:45:00Z',
});

/// Mounts [screen] with a faked profile controller and returns it.
Future<FakeUserProfileController> _pump(
  WidgetTester tester,
  Widget screen, {
  ThemeMode mode = ThemeMode.light,
  UserModel? user,
  bool loading = false,
}) async {
  // Tall surface so the whole page builds; a lazy ListView skips off-screen
  // rows on the default 800x600 test viewport.
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.reset();
  Get.put<ThemeController>(ThemeController(initialMode: ThemeMode.light));

  final controller = FakeUserProfileController();
  Get.put<UserProfileController>(controller);
  controller.user.value = user;
  controller.isLoading.value = loading;

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: screen,
    ),
  );
  // Settles the async local-profile read in SettingsScreen.initState.
  await tester.pump();
  await tester.pump();

  return controller;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'userRole': 'Admin',
      'userName': 'Jane Wanjiku Doe',
      'phone': '+254 712 345 678',
    });
  });

  tearDown(Get.reset);

  group('AccountScreen', () {
    testWidgets('renders the profile details', (tester) async {
      await _pump(tester, const AccountScreen(), user: _sampleUser());

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Jane Wanjiku Doe'), findsWidgets);
      expect(find.text('jane.doe@atomiot.live'), findsWidgets);
      expect(find.text('+254 712 345 678'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Member Since'), findsOneWidget);
      expect(find.text('Last Sign In'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not surface the user role', (tester) async {
      await _pump(tester, const AccountScreen(), user: _sampleUser());

      expect(find.text('Admin'), findsNothing);
      expect(find.text('Role'), findsNothing);
    });

    testWidgets('shows a loader while the profile is still loading', (
      tester,
    ) async {
      await _pump(tester, const AccountScreen(), loading: true);

      expect(find.text('Full Name'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers a retry when there is no user', (tester) async {
      final controller = await _pump(tester, const AccountScreen());

      expect(find.text('No user data found'), findsOneWidget);

      // onInit already fires one fetch via a post-frame callback, so assert
      // that Retry adds another rather than pinning an absolute count.
      final before = controller.fetchCount;
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(controller.fetchCount, before + 1);
    });

    testWidgets('renders in dark mode', (tester) async {
      await _pump(
        tester,
        const AccountScreen(),
        user: _sampleUser(),
        mode: ThemeMode.dark,
      );

      expect(find.text('Jane Wanjiku Doe'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders the hero and the setting groups', (tester) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Jane Wanjiku Doe'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('GENERAL SETTINGS'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('INFORMATION'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not surface the user role', (tester) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());

      expect(find.text('Admin'), findsNothing);
    });

    testWidgets('keeps a single entry point to Account Details', (
      tester,
    ) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());

      expect(find.text('Account Details'), findsOneWidget);
    });

    testWidgets('shows the Managers tile only for admins', (tester) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());
      expect(find.text('Managers'), findsOneWidget);

      SharedPreferences.setMockInitialValues({'userRole': 'Driver'});
      await _pump(tester, const SettingsScreen(), user: _sampleUser());
      expect(find.text('Managers'), findsNothing);
    });

    testWidgets('shows notification permissions only for admins and superadmins', (
      tester,
    ) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());
      expect(find.text('Notifications'), findsOneWidget);

      SharedPreferences.setMockInitialValues({'userRole': 'superadmin'});
      await _pump(tester, const SettingsScreen(), user: _sampleUser());
      expect(find.text('Notifications'), findsOneWidget);

      SharedPreferences.setMockInitialValues({'userRole': 'Driver'});
      await _pump(tester, const SettingsScreen(), user: _sampleUser());
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('appearance control changes the theme mode', (tester) async {
      await _pump(tester, const SettingsScreen(), user: _sampleUser());

      expect(ThemeController.to.mode.value, ThemeMode.light);

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(ThemeController.to.mode.value, ThemeMode.dark);
    });
  });
}
