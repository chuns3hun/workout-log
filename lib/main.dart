import 'package:flutter/material.dart';

void main() => runApp(const WorkoutLogApp());

class Exercise {
  const Exercise(this.name, this.part);
  final String name;
  final String part;
}

class SetRecord {
  SetRecord({
    required this.exercise,
    required this.weight,
    required this.reps,
    required this.date,
  });
  final Exercise exercise;
  final double weight;
  final int reps;
  final DateTime date;
}

// 10주차는 목표와 종목을 코드에 넣어 둔 예시 데이터로 시작한다.
// 목표 설정, 종목 추가는 11주차, 기기 저장은 12주차에 붙인다.
const List<String> parts = ['가슴', '등', '하체', '어깨', '팔'];

const Map<String, int> weeklyGoals = {
  '가슴': 12,
  '등': 12,
  '하체': 9,
  '어깨': 9,
  '팔': 6,
};

const List<Exercise> exercises = [
  Exercise('벤치프레스', '가슴'),
  Exercise('덤벨 프레스', '가슴'),
  Exercise('랫풀다운', '등'),
  Exercise('바벨 로우', '등'),
  Exercise('스쿼트', '하체'),
  Exercise('레그 프레스', '하체'),
  Exercise('숄더 프레스', '어깨'),
  Exercise('바벨 컬', '팔'),
];

// 예시 기록: 가슴 8세트(AC1 확인용), 하체 10세트(AC6 확인용)
List<SetRecord> sampleRecords() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < 8; i++)
      SetRecord(exercise: exercises[0], weight: 60, reps: 10, date: now),
    for (var i = 0; i < 10; i++)
      SetRecord(exercise: exercises[4], weight: 80, reps: 8, date: now),
  ];
}

// 이번 주 월요일 0시. DateTime.weekday는 월요일이 1이다.
DateTime startOfWeek(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: now.weekday - 1));
}

class WorkoutLogApp extends StatelessWidget {
  const WorkoutLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeeklyGoalScreen(),
    );
  }
}

class WeeklyGoalScreen extends StatefulWidget {
  const WeeklyGoalScreen({super.key});

  @override
  State<WeeklyGoalScreen> createState() => _WeeklyGoalScreenState();
}

class _WeeklyGoalScreenState extends State<WeeklyGoalScreen> {
  final List<SetRecord> _records = sampleRecords();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  Exercise? _selected;
  String? _exerciseError;
  String? _weightError;
  String? _repsError;

  // 한 세트 수, 남은 세트 수는 저장하지 않고 기록에서 계산한다.
  int doneSets(String part) {
    final start = startOfWeek(DateTime.now());
    return _records
        .where((r) => r.exercise.part == part && !r.date.isBefore(start))
        .length;
  }

  int remainingSets(String part) {
    final left = weeklyGoals[part]! - doneSets(part);
    return left < 0 ? 0 : left;
  }

  void _saveSet() {
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());

    setState(() {
      _exerciseError = _selected == null ? '종목을 골라 주세요' : null;
      _weightError = (weight == null || weight < 0 || weight > 500)
          ? '무게를 올바르게 입력하세요'
          : null;
      _repsError = (reps == null || reps < 1 || reps > 100)
          ? '횟수를 올바르게 입력하세요'
          : null;

      if (_exerciseError != null || _weightError != null || _repsError != null) {
        return;
      }

      _records.add(SetRecord(
        exercise: _selected!,
        weight: weight!,
        reps: reps!,
        date: DateTime.now(),
      ));
      // 다음 세트도 같은 무게로 하는 경우가 많아서 무게는 남겨 둔다.
      _repsController.clear();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이번 주 목표')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '예시 데이터로 실행 중입니다. 앱을 끄면 기록이 사라집니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            for (final part in parts) _buildPartProgress(part),
            const Divider(height: 32),
            const Text(
              '세트 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in exercises)
                  ChoiceChip(
                    label: Text('${e.name} (${e.part})'),
                    selected: _selected == e,
                    onSelected: (_) {
                      setState(() {
                        _selected = e;
                        _exerciseError = null;
                      });
                    },
                  ),
              ],
            ),
            if (_exerciseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _exerciseError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '무게 (kg)',
                      errorText: _weightError,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '횟수',
                      errorText: _repsError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveSet,
              child: const Text('기록'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartProgress(String part) {
    final goal = weeklyGoals[part]!;
    final done = doneSets(part);
    final left = remainingSets(part);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                part,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(left == 0 ? '목표 달성' : '$left세트 남음'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: done >= goal ? 1.0 : done / goal),
          const SizedBox(height: 2),
          Text(
            '$done / $goal세트',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
