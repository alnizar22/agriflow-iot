import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/main.dart';

void main() {
  testWidgets('Aplikasi Irigasi Bawang renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const IrigasiBawangApp());
    expect(find.text('IRIGASI IOT'), findsWidgets);
  });
}
