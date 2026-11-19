import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/widgets/developer_profile_dialog.dart';

void main() {
  testWidgets('DeveloperProfileDialog displays complete academic identity', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeveloperProfileDialog.show(context),
              child: const Text('Open Profile'),
            ),
          ),
        ),
      ),
    );

    // Tap to open dialog
    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();

    // Verify academic identity fields
    expect(find.text('Informasi Pengembang'), findsOneWidget);
    expect(find.textContaining('Sarjana Komputer (S.Kom)'), findsOneWidget);
    expect(find.text('STMIK WIDYA UTAMA'), findsOneWidget);
    expect(find.text('EVA YUNIZAR SUGIARTO'), findsOneWidget);
    expect(find.text('STI202202907'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.textContaining('RANCANG BANGUN SISTEM KONTROL DAN MONITORING'), findsOneWidget);

    // Verify Tutup button dismisses the dialog
    expect(find.text('Tutup'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Informasi Pengembang'), findsNothing);
  });
}
