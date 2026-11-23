---
name: prd-check
description: workout-log에서 요구사항(F1~F6) 하나를 PRD와 대조해 확인하고 IMPLEMENTATION.md를 갱신할 때 사용한다.
---

# PRD 구현 확인

입력: `docs/PRD.md`, `IMPLEMENTATION.md`, 확인할 요구사항 ID, 관련 코드(`lib/main.dart`, `test/widget_test.dart`).

1. `docs/PRD.md`에서 대상 ID의 설명, 8장 데이터 규칙, 관련 AC를 찾아 적는다. 모호하면 질문하고 임의로 채우지 않는다.
2. 관련 코드에서 각 AC가 어디서 처리되는지 찾는다. 처리하는 코드가 없으면 미구현이다.
3. `flutter analyze`와 `flutter test`를 실행하고, 대상 AC에 해당하는 테스트가 있는지 확인한다.
4. 화면에서 직접 확인할 정상 입력과 경계 입력을 목록으로 만든다. 직접 확인은 내가 하고 결과를 알려 준다.
5. 상태를 정한다. 미구현 / 구현·미검증 / 확인 완료 / 실패 / 미실행 중 하나다. 확인 완료는 테스트나 직접 실행으로 확인한 AC에만 쓴다.
6. `IMPLEMENTATION.md`의 해당 행에 상태, 코드 위치, 확인 근거(명령·날짜·장치), 남은 일을 적는다.

실행하지 못한 검사는 이유와 함께 미실행으로 적는다. PRD의 요구사항을 현재 구현에 맞춰 줄이지 않는다.
