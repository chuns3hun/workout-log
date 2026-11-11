import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_log/main.dart';

// 종목을 고르고 무게·횟수를 입력한 뒤 기록 버튼을 누른다.
Future<void> recordSet(
  WidgetTester tester, {
  required String exercise,
  required String weight,
  required String reps,
}) async {
  final chip = find.widgetWithText(ChoiceChip, exercise);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump();

  await tester.enterText(find.widgetWithText(TextField, '무게 (kg)'), weight);
  await tester.enterText(find.widgetWithText(TextField, '횟수'), reps);

  final button = find.widgetWithText(ElevatedButton, '기록');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('AC1 가슴 12세트 중 8세트를 했으면 4세트 남음', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    expect(find.text('8 / 12세트'), findsOneWidget);
    expect(find.text('4세트 남음'), findsOneWidget);
  });

  testWidgets('AC2 순서와 상관없이 가슴 종목을 기록하면 남은 세트가 1 줄어듦',
      (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    await recordSet(tester, exercise: '덤벨 프레스 (가슴)', weight: '24', reps: '10');

    expect(find.text('9 / 12세트'), findsOneWidget);
    expect(find.text('3세트 남음'), findsOneWidget);
  });

  testWidgets('AC4 잘못된 횟수는 저장되지 않음', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    for (final reps in ['', '0', 'abc', '101']) {
      await recordSet(tester, exercise: '덤벨 프레스 (가슴)', weight: '24', reps: reps);

      expect(find.text('횟수를 올바르게 입력하세요'), findsOneWidget);
      expect(find.text('4세트 남음'), findsOneWidget);
    }
  });

  testWidgets('AC6 목표보다 많이 하면 목표 달성, 음수 없음', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    expect(find.text('10 / 9세트'), findsOneWidget);
    expect(find.text('목표 달성'), findsOneWidget);
    expect(find.textContaining('-'), findsNothing);
  });
}
