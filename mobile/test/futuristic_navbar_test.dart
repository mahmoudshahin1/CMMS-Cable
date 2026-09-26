import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bar/nav_bar.dart';

void main() {
  testWidgets('FuturisticNavBar renders and toggles items', (tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: FuturisticNavBar(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() => selectedIndex = index);
                },
                items: [
                  NavBarItem(icon: Icons.factory_rounded, label: 'Factory'),
                  NavBarItem(icon: Icons.build_rounded, label: 'Work Orders'),
                  NavBarItem(
                    icon: Icons.notifications_rounded,
                    label: 'Alerts',
                    hasNotification: true,
                    notificationCount: 3,
                  ),
                ],
                style: NavBarStyle.obsidian,
                blurSigma: 15.0, // High-precision blur
                theme: FuturisticTheme.molten(),
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(FuturisticNavBar), findsOneWidget);
    expect(find.text('Factory'), findsOneWidget);

    // Tap on the second item by icon
    await tester.tap(find.byIcon(Icons.build_rounded));
    await tester.pump(const Duration(milliseconds: 600));

    expect(selectedIndex, 1);
    expect(find.text('Work Orders'), findsOneWidget);
  });
}
