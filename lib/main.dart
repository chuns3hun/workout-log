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
  Map<String, int> _goals = Map.of(weeklyGoals);
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
    final goal = _goals[part] ?? 0;
    final left = goal - doneSets(part);
    return left < 0 ? 0 : left;
  }

  // 부위별 남은 세트를 더한 값. 목표를 넘긴 부위는 0으로 세서 다른 부위 남은 세트를 깎지 않는다.
  int totalRemainingSets() {
    return parts.fold(0, (sum, part) => sum + remainingSets(part));
  }

  // 직전 기록도 따로 저장하지 않고, 그 종목의 가장 마지막 기록을 찾는다.
  // 기록은 시간 순서대로 리스트 뒤에 붙으니 뒤에서부터 찾으면 된다.
  SetRecord? lastRecordOf(Exercise exercise) {
    for (final r in _records.reversed) {
      if (r.exercise == exercise) return r;
    }
    return null;
  }

  // 60.0은 60으로, 22.5는 그대로 보여 준다.
  String formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toString();
  }

  String lastRecordText() {
    if (_selected == null) return '';
    final last = lastRecordOf(_selected!);
    if (last == null) return '직전 기록 없음';
    return '직전 기록: ${formatWeight(last.weight)}kg × ${last.reps}회';
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

  Future<void> _openGoalSettings() async {
    final updated = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (context) => GoalSettingScreen(currentGoals: _goals),
      ),
    );
    if (updated != null) {
      setState(() {
        _goals = updated;
      });
    }
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
      appBar: AppBar(
        title: const Text('이번 주 목표'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '목표 설정',
            onPressed: _openGoalSettings,
          ),
        ],
      ),
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
            _buildTotalRemaining(),
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
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(lastRecordText()),
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

  Widget _buildTotalRemaining() {
    final total = totalRemainingSets();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('이번 주 남은 세트', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            total == 0 ? '이번 주 목표 모두 달성' : '$total세트',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPartProgress(String part) {
    final goal = _goals[part] ?? 0;
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
          LinearProgressIndicator(
            value: goal == 0
                ? 1.0
                : (done >= goal ? 1.0 : done / goal),
          ),
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

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key, required this.currentGoals});

  final Map<String, int> currentGoals;

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final part in parts)
        part: TextEditingController(
          text: (widget.currentGoals[part] ?? 0).toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveGoals() {
    final newGoals = <String, int>{};
    final newErrors = <String, String?>{};
    var hasError = false;

    for (final part in parts) {
      final text = _controllers[part]!.text.trim();
      final value = int.tryParse(text);
      if (value == null || value < 1 || value > 50) {
        newErrors[part] = '1 이상 50 이하 숫자를 입력하세요';
        hasError = true;
      } else {
        newGoals[part] = value;
        newErrors[part] = null;
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(newErrors);
    });

    if (!hasError) {
      Navigator.pop(context, newGoals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 목표 설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '부위별 주간 목표 세트 수를 설정합니다 (1~50세트).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            for (final part in parts) ...[
              TextField(
                key: ValueKey('goal_input_$part'),
                controller: _controllers[part],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '$part 목표 세트 수',
                  errorText: _errors[part],
                  suffixText: '세트',
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveGoals,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
