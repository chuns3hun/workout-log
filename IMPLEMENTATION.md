# 구현 현황

`docs/PRD.md`에는 만들 기능을, 이 문서에는 실제로 만든 것과 확인 결과를 적는다.

- 마지막 확인: 2026-11-23 (F1~F6)
- 환경: Flutter 3.47.4, Dart 3.13.3, Windows 11
- 장치: Android 에뮬레이터 Medium Phone(Android 17, API 37), Chrome(웹)
- 기준 커밋: 063057d (F6 기기 저장)

상태: 미구현 / 구현·미검증 / 확인 완료 / 실패 / 미실행

| 요구 ID | 내용 | 상태 | 관련 코드 | 확인 근거 | 남은 일 |
| --- | --- | --- | --- | --- | --- |
| F1 | 부위별 남은 세트, 이번 주 합계 | 확인 완료 | `lib/main.dart` `remainingSets`, `totalRemainingSets`, `startOfWeek` | AC1·AC6·AC10 위젯 테스트, AC3 단위 테스트 통과. AC10은 11/18 Chrome에서 31 → 30세트 확인 | 없음 |
| F2 | 세트 기록(무게·횟수) | 확인 완료 | `lib/main.dart` 세트 기록 칸 | AC2·AC4 위젯 테스트 통과, 10주차 직접 실행 확인([week10/first-screen.md](week10/first-screen.md)) | 없음 |
| F3 | 종목 추가 | 확인 완료 | `lib/main.dart` `AddExerciseScreen` | F3-1~3 위젯 테스트 통과, 11/18 Chrome 직접 확인 | "벤치프레스"와 "벤치 프레스"는 다른 종목으로 들어감. 써 보며 판단 |
| F4 | 직전 기록 표시 | 확인 완료 | `lib/main.dart` 직전 기록 문구 | AC7~AC9 위젯 테스트 통과, 11/18 Chrome 직접 확인 | 없음 |
| F5 | 주간 목표 설정 | 확인 완료 | `lib/main.dart` `GoalSettingScreen` | F5-1~3 위젯 테스트 통과, 11/16 에뮬레이터 직접 확인 | 없음 |
| F6 | 기기 저장(앱을 껐다 켜도 종목·목표·기록 유지) | 확인 완료 | `lib/main.dart` `WorkoutStorage`, `_WeeklyGoalScreenState` | F6-1~5 위젯 테스트 통과 (2026-11-23, Windows). 2026-11-23 Chrome 직접 확인: F6-1(첫 실행 빈 상태 48세트), F6-2(세트 기록·남은 세트·직전 기록 유지), F6-4(종목 추가 유지), F6-3(목표 변경 유지), 새로고침 및 터미널 재실행 유지 확인. F6-5는 테스트로만 확인(화면 미확인). Android는 미실행 | Android 환경에서 직접 실행 확인 |

AC5(목표가 하나도 없을 때 안내)는 지금 구조에서 생길 수 없는 상태라 PRD에서 범위를 뺐다. 이유는 `docs/PRD.md` 완료 기준 아래에 있다.

## 검사 기록

| 명령·행동 | 실제 결과 | 날짜·장치 |
| --- | --- | --- |
| dart format | 포맷팅 완료 (lib/main.dart, test/widget_test.dart) | 2026-11-23, Windows |
| flutter analyze | No issues found! (ran in 4.7s) | 2026-11-23, Windows |
| flutter test | 20개 모두 통과 | 2026-11-23, Windows |
| 직접 실행 (F6 기기 저장) | 첫 실행 48세트, 기록·종목·목표 변경 후 새로고침 및 재실행 시 유지 확인(F6-1~4). F6-5는 화면 미확인(테스트로만 검증). Android는 미실행 | 2026-11-23, Chrome (확인) / Android (미실행) |
| 직접 실행 (F3·F4·합계) | 기대와 같음 | 2026-11-18, Chrome |
| 직접 실행 (F5) | 기대와 같음 | 2026-11-16, Android 에뮬레이터 |

자세한 입력과 결과는 [week11/check.md](week11/check.md)(F1~F5)와 [week12/check.md](week12/check.md)(F6)에 있다.

## 문제

- 2026-11-18 에뮬레이터가 시작하다 꺼짐(exit code 1). 원인은 확인하지 않았고, 그날 확인은 Chrome으로 대신했다.
- 2026-11-23 기준 F6 기기 저장은 Chrome(웹)에서만 직접 확인했고, Android 기기/에뮬레이터에서는 아직 확인하지 못했다.

## 다음 작업

- Android 환경에서 F6 저장 기능 직접 확인.
- F6 뒤에 한 주 동안 직접 써 보며 빠진 부위가 줄었는지 확인한다(15주차 시연 목표 4번).
