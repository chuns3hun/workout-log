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

  // 입력칸에 남은 커서 손잡이가 기록 버튼을 가리지 않게 포커스를 뺀다.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

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

  testWidgets('AC7 기록이 있는 종목을 고르면 직전 기록이 보임', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    final chip = find.widgetWithText(ChoiceChip, '벤치프레스 (가슴)');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    expect(find.text('직전 기록: 60kg × 10회'), findsOneWidget);
  });

  testWidgets('AC8 기록이 없는 종목은 직전 기록 없음', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    final chip = find.widgetWithText(ChoiceChip, '덤벨 프레스 (가슴)');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    expect(find.text('직전 기록 없음'), findsOneWidget);
  });

  testWidgets('AC9 기록을 저장하면 직전 기록이 방금 기록으로 바뀜', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    await recordSet(tester, exercise: '덤벨 프레스 (가슴)', weight: '22.5', reps: '12');

    expect(find.text('직전 기록: 22.5kg × 12회'), findsOneWidget);
  });

  testWidgets('AC6 목표보다 많이 하면 목표 달성, 음수 없음', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    expect(find.text('10 / 9세트'), findsOneWidget);
    expect(find.text('목표 달성'), findsOneWidget);
    expect(find.textContaining('-'), findsNothing);
  });

  testWidgets('F5 목표를 변경하면 첫 화면의 남은 세트가 바로 다시 계산됨', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    // 초기 상태: 가슴 8/12세트, 4세트 남음
    expect(find.text('8 / 12세트'), findsOneWidget);
    expect(find.text('4세트 남음'), findsOneWidget);

    // 목표 설정 화면 열기
    await tester.tap(find.byTooltip('목표 설정'));
    await tester.pumpAndSettle();

    expect(find.text('주간 목표 설정'), findsOneWidget);

    // 가슴 목표를 10으로 변경
    final chestInput = find.byKey(const ValueKey('goal_input_가슴'));
    await tester.ensureVisible(chestInput);
    await tester.enterText(chestInput, '10');
    await tester.pump();

    // 저장 버튼 누르기
    final saveButton = find.widgetWithText(ElevatedButton, '저장');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 첫 화면으로 돌아오고 남은 세트가 즉시 다시 계산됨 (10 - 8 = 2)
    expect(find.text('주간 목표 설정'), findsNothing);
    expect(find.text('8 / 10세트'), findsOneWidget);
    expect(find.text('2세트 남음'), findsOneWidget);
  });

  testWidgets('F5 잘못된 목표값(1 미만, 50 초과, 빈칸, 문자)은 저장되지 않고 안내 문구 표시',
      (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    await tester.tap(find.byTooltip('목표 설정'));
    await tester.pumpAndSettle();

    final chestInput = find.byKey(const ValueKey('goal_input_가슴'));
    final saveButton = find.widgetWithText(ElevatedButton, '저장');

    for (final invalid in ['0', '51', '', 'abc']) {
      await tester.ensureVisible(chestInput);
      await tester.enterText(chestInput, invalid);
      await tester.pump();

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      // 안내 문구 확인 및 화면이 유지되는지 확인
      expect(find.text('1 이상 50 이하 숫자를 입력하세요'), findsOneWidget);
      expect(find.text('주간 목표 설정'), findsOneWidget);
    }
  });

  testWidgets('F5 저장하지 않고 뒤로 가기로 나오면 기존 목표 유지', (tester) async {
    await tester.pumpWidget(const WorkoutLogApp());

    // 초기 상태 확인
    expect(find.text('8 / 12세트'), findsOneWidget);
    expect(find.text('4세트 남음'), findsOneWidget);

    // 목표 설정 진입 후 가슴 목표를 15로 수정
    await tester.tap(find.byTooltip('목표 설정'));
    await tester.pumpAndSettle();

    final chestInput = find.byKey(const ValueKey('goal_input_가슴'));
    await tester.ensureVisible(chestInput);
    await tester.enterText(chestInput, '15');
    await tester.pump();

    // 저장하지 않고 뒤로 가기(BackButton) 탭
    final backButton = find.byType(BackButton);
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // 첫 화면에서 기존 목표(12)와 남은 세트(4)가 그대로 유지됨
    expect(find.text('주간 목표 설정'), findsNothing);
    expect(find.text('8 / 12세트'), findsOneWidget);
    expect(find.text('4세트 남음'), findsOneWidget);
    expect(find.text('8 / 15세트'), findsNothing);
  });
}
