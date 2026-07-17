import 'package:atom/config/app_theme.dart';
import 'package:atom/utils/signal_tier.dart';
import 'package:atom/widgets/vehicle/vehicle_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: brightness,
      extensions: [
        brightness == Brightness.dark ? AppColors.dark : AppColors.light,
      ],
    ),
    home: Scaffold(
      body: SafeArea(child: SingleChildScrollView(child: child)),
    ),
  );
}

// The hero's live dot pulses on a repeating controller, so pumpAndSettle would
// never return. Every test here pumps discrete frames instead.

void main() {
  group('signalBarsLit', () {
    test('lights more bars for a stronger tier', () {
      // SignalTier lists its strongest tier first, so a naive `index + 1`
      // inverts the meter.
      expect(signalBarsLit(SignalTier.excellent), 4);
      expect(signalBarsLit(SignalTier.good), 3);
      expect(signalBarsLit(SignalTier.fair), 2);
      expect(signalBarsLit(SignalTier.poor), 1);
    });

    test('never lights zero or overflows the meter', () {
      for (final tier in SignalTier.values) {
        expect(signalBarsLit(tier), greaterThan(0));
        expect(signalBarsLit(tier), lessThanOrEqualTo(4));
      }
    });
  });

  group('VehicleHeroCard', () {
    testWidgets('an online vehicle reports speed, signal and live state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: true,
            speedKph: 47.4,
            signalTier: SignalTier.excellent,
            location: 'Kilimani, Nairobi',
          ),
        ),
      );

      expect(find.text('Premio'), findsOneWidget);
      expect(find.text('Toyota'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('km/h'), findsOneWidget);
      expect(find.text('In motion'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('Kilimani, Nairobi'), findsOneWidget);
    });

    testWidgets('a stopped vehicle reads as stationary, not in motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: true,
            speedKph: 0,
            signalTier: SignalTier.good,
            location: 'Kilimani, Nairobi',
          ),
        ),
      );

      expect(find.text('Stationary'), findsOneWidget);
      expect(find.text('In motion'), findsNothing);
    });

    testWidgets('an offline vehicle suppresses the signal tier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: false,
            speedKph: 0,
            signalTier: SignalTier.excellent,
            location: 'Kilimani, Nairobi',
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
      expect(find.text('No signal'), findsOneWidget);
      // The stale tier must not be presented as a current reading.
      expect(find.text('Excellent'), findsNothing);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('falls back when the make is blank', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: '',
            isOnline: true,
            speedKph: 0,
            signalTier: SignalTier.fair,
            location: 'Kilimani, Nairobi',
          ),
        ),
      );

      expect(find.text('Tracked vehicle'), findsOneWidget);
    });

    testWidgets('the location footer opens the map when a position exists', (
      tester,
    ) async {
      var opened = false;

      await tester.pumpWidget(
        _testApp(
          VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: true,
            speedKph: 0,
            signalTier: SignalTier.good,
            location: 'Kilimani, Nairobi',
            onLocationTap: () => opened = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Kilimani, Nairobi'));
      expect(opened, isTrue);
    });

    testWidgets('the footer is inert and hides its chevron with no position', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: false,
            speedKph: 0,
            signalTier: SignalTier.poor,
            location: 'Location unavailable',
          ),
        ),
      );

      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const VehicleHeroCard(
            model: 'Premio',
            make: 'Toyota',
            isOnline: true,
            speedKph: 12,
            signalTier: SignalTier.good,
            location: 'Kilimani, Nairobi',
          ),
          brightness: Brightness.dark,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('12'), findsOneWidget);
    });
  });

  group('VehicleEngineCard', () {
    testWidgets('a running engine offers a switch', (tester) async {
      await tester.pumpWidget(
        _testApp(
          VehicleEngineCard(
            isEngineOn: true,
            isBusy: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Engine Control'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.byIcon(Icons.power_rounded), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('an off engine reads as immobilized', (tester) async {
      await tester.pumpWidget(
        _testApp(
          VehicleEngineCard(
            isEngineOn: false,
            isBusy: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Immobilized'), findsOneWidget);
      expect(find.byIcon(Icons.power_off_rounded), findsOneWidget);
    });

    testWidgets('an in-flight command replaces the switch with a spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          VehicleEngineCard(
            isEngineOn: true,
            isBusy: true,
            onChanged: (_) {},
          ),
        ),
      );

      // No switch means the command cannot be re-sent while one is running.
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('toggling reports the requested state', (tester) async {
      bool? requested;

      await tester.pumpWidget(
        _testApp(
          VehicleEngineCard(
            isEngineOn: true,
            isBusy: false,
            onChanged: (value) => requested = value,
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(requested, isFalse);
    });
  });

  group('VehicleQuickActionGrid', () {
    testWidgets('paired tiles share a height despite uneven descriptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          VehicleQuickActionGrid(
            actions: [
              VehicleQuickAction(
                title: 'Short',
                description: 'One',
                icon: Icons.route,
                color: Colors.blue,
                onTap: () {},
              ),
              VehicleQuickAction(
                title: 'Long',
                description: 'A far longer description that must wrap lines',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      final first = tester.getSize(find.byType(VehicleQuickAction).at(0));
      final second = tester.getSize(find.byType(VehicleQuickAction).at(1));
      expect(first.height, second.height);
    });

    testWidgets('an odd number of actions leaves the last row half-filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          VehicleQuickActionGrid(
            actions: [
              VehicleQuickAction(
                title: 'One',
                description: 'First',
                icon: Icons.route,
                color: Colors.blue,
                onTap: () {},
              ),
              VehicleQuickAction(
                title: 'Two',
                description: 'Second',
                icon: Icons.route,
                color: Colors.blue,
                onTap: () {},
              ),
              VehicleQuickAction(
                title: 'Three',
                description: 'Third',
                icon: Icons.route,
                color: Colors.blue,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(VehicleQuickAction), findsNWidgets(3));
    });

    testWidgets('a tile invokes its action', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _testApp(
          VehicleQuickActionGrid(
            actions: [
              VehicleQuickAction(
                title: 'Violations',
                description: 'Alerts',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Violations'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('VehicleGroupCard', () {
    testWidgets('divides rows without a trailing rule', (tester) async {
      await tester.pumpWidget(
        _testApp(
          VehicleGroupCard(
            children: [
              VehicleActionTile(
                icon: Icons.info_outline_rounded,
                title: 'Details',
                subtitle: 'Records',
                onTap: () {},
              ),
              VehicleActionTile(
                icon: Icons.tune_rounded,
                title: 'Commands',
                subtitle: 'Send',
                onTap: () {},
              ),
              VehicleActionTile(
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                subtitle: 'Trips',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('a tile carries an optional badge and invokes its action', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _testApp(
          VehicleGroupCard(
            children: [
              VehicleActionTile(
                icon: Icons.verified_outlined,
                title: 'Certificate',
                subtitle: 'Expires 01 Jan 2026',
                badge: const VehicleStatusBadge(
                  label: 'Expired',
                  color: Colors.red,
                ),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
      await tester.tap(find.text('Certificate'));
      expect(tapped, isTrue);
    });
  });

  group('VehicleAlertBanner', () {
    testWidgets('surfaces the problem and runs its single fix', (tester) async {
      var renewed = false;

      await tester.pumpWidget(
        _testApp(
          VehicleAlertBanner(
            icon: Icons.gpp_maybe_rounded,
            title: 'Certificate expired',
            message: 'Renew to keep this vehicle compliant.',
            actionLabel: 'Renew',
            onAction: () => renewed = true,
          ),
        ),
      );

      expect(find.text('Certificate expired'), findsOneWidget);
      await tester.tap(find.text('Renew'));
      expect(renewed, isTrue);
    });
  });
}
