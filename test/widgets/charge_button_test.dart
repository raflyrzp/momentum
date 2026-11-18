import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/features/today/charge_button.dart';

void main() {
  Future<({int Function() charged, int Function() hints})> pumpButton(
    WidgetTester tester, {
    bool done = false,
  }) async {
    var charged = 0;
    var hints = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ChargeButton(
            done: done,
            onCharged: () => charged++,
            onShortTap: () => hints++,
          ),
        ),
      ),
    );
    return (charged: () => charged, hints: () => hints);
  }

  testWidgets('menahan 0,8 detik menyelesaikan kebiasaan sekali', (
    tester,
  ) async {
    final counts = await pumpButton(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ChargeButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 790));
    expect(counts.charged(), 0);

    await tester.pump(const Duration(milliseconds: 20));
    expect(counts.charged(), 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(counts.charged(), 1);
    expect(counts.hints(), 0);
  });

  testWidgets('melepas sebelum penuh membatalkan dan memberi petunjuk', (
    tester,
  ) async {
    final counts = await pumpButton(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ChargeButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(counts.charged(), 0);
    expect(counts.hints(), 1);
  });

  testWidgets('tombol yang sudah selesai tidak bisa diisi lagi', (
    tester,
  ) async {
    final counts = await pumpButton(tester, done: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ChargeButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(counts.charged(), 0);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
