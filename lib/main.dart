import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await WorkoutStorage.init();
  } catch (_) {}
  runApp(const WorkoutLogApp());
}

class Exercise {
  const Exercise(this.name, this.part);
  final String name;
  final String part;

  Map<String, dynamic> toJson() => {'name': name, 'part': part};

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(json['name'] as String, json['part'] as String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          part == other.part;

  @override
  int get hashCode => Object.hash(name, part);
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

  Map<String, dynamic> toJson() => {
    'exercise': exercise.toJson(),
    'weight': weight,
    'reps': reps,
    'date': date.toIso8601String(),
  };

  factory SetRecord.fromJson(Map<String, dynamic> json) {
    return SetRecord(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

// 10주차는 목표와 종목을 코드에 넣어 둔 예시 데이터로 시작했다.
// 목표 설정, 종목 추가는 11주차, 기기 저장은 12주차에 붙였다.
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

class WorkoutStorage {
  static const String exercisesKey = 'workout_exercises';
  static const String goalsKey = 'workout_goals';
  static const String recordsKey = 'workout_records';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static SharedPreferences? get prefs => _prefs;

  static List<Exercise> loadExercises(SharedPreferences? prefs) {
    if (prefs == null) return List.of(exercises);
    try {
      final jsonStr = prefs.getString(exercisesKey);
      if (jsonStr == null) return List.of(exercises);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.of(exercises);
    }
  }

  static Future<void> saveExercises(List<Exercise> exerciseList) async {
    try {
      final p = _prefs ?? await init();
      final jsonStr = jsonEncode(exerciseList.map((e) => e.toJson()).toList());
      await p.setString(exercisesKey, jsonStr);
    } catch (_) {}
  }

  static Map<String, int> loadGoals(SharedPreferences? prefs) {
    if (prefs == null) return Map.of(weeklyGoals);
    try {
      final jsonStr = prefs.getString(goalsKey);
      if (jsonStr == null) return Map.of(weeklyGoals);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return Map.of(weeklyGoals);
    }
  }

  static Future<void> saveGoals(Map<String, int> goalMap) async {
    try {
      final p = _prefs ?? await init();
      final jsonStr = jsonEncode(goalMap);
      await p.setString(goalsKey, jsonStr);
    } catch (_) {}
  }

  static List<SetRecord> loadRecords(SharedPreferences? prefs) {
    if (prefs == null) return [];
    try {
      final jsonStr = prefs.getString(recordsKey);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => SetRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecords(List<SetRecord> recordList) async {
    try {
      final p = _prefs ?? await init();
      final jsonStr = jsonEncode(recordList.map((r) => r.toJson()).toList());
      await p.setString(recordsKey, jsonStr);
    } catch (_) {}
  }
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
  late List<SetRecord> _records;
  late List<Exercise> _exercises;
  late Map<String, int> _goals;
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  Exercise? _selected;
  String? _exerciseError;
  String? _weightError;
  String? _repsError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final prefs = WorkoutStorage.prefs;
    _exercises = WorkoutStorage.loadExercises(prefs);
    _goals = WorkoutStorage.loadGoals(prefs);
    _records = WorkoutStorage.loadRecords(prefs);

    if (prefs == null) {
      WorkoutStorage.init()
          .then((p) {
            if (!mounted) return;
            setState(() {
              _exercises = WorkoutStorage.loadExercises(p);
              _goals = WorkoutStorage.loadGoals(p);
              _records = WorkoutStorage.loadRecords(p);
            });
          })
          .catchError((_) {});
    }
  }

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

      if (_exerciseError != null ||
          _weightError != null ||
          _repsError != null) {
        return;
      }

      _records.add(
        SetRecord(
          exercise: _selected!,
          weight: weight!,
          reps: reps!,
          date: DateTime.now(),
        ),
      );
      // 다음 세트도 같은 무게로 하는 경우가 많아서 무게는 남겨 둔다.
      _repsController.clear();
    });
    WorkoutStorage.saveRecords(_records);
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
      WorkoutStorage.saveGoals(_goals);
    }
  }

  Future<void> _openAddExercise() async {
    final newExercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          existingNames: _exercises.map((e) => e.name).toList(),
        ),
      ),
    );
    if (newExercise != null) {
      setState(() {
        _exercises.add(newExercise);
        _selected = newExercise;
        _exerciseError = null;
      });
      WorkoutStorage.saveExercises(_exercises);
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
            _buildTotalRemaining(),
            const SizedBox(height: 8),
            for (final part in parts) _buildPartProgress(part),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '세트 기록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _openAddExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('종목 추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _exercises)
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
            ElevatedButton(onPressed: _saveSet, child: const Text('기록')),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(left == 0 ? '목표 달성' : '$left세트 남음'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: goal == 0 ? 1.0 : (done >= goal ? 1.0 : done / goal),
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
      appBar: AppBar(title: const Text('주간 목표 설정')),
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
            ElevatedButton(onPressed: _saveGoals, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key, required this.existingNames});

  final List<String> existingNames;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _nameController = TextEditingController();
  String _selectedPart = parts.first;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    final trimmedName = _nameController.text.trim();

    setState(() {
      if (trimmedName.isEmpty) {
        _nameError = '종목 이름을 입력하세요';
        return;
      }
      if (widget.existingNames.contains(trimmedName)) {
        _nameError = '이미 등록된 종목입니다';
        return;
      }
      _nameError = null;
    });

    if (_nameError == null) {
      Navigator.pop(context, Exercise(trimmedName, _selectedPart));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('종목 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('exercise_name_input'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '종목 이름',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('exercise_part_dropdown'),
              initialValue: _selectedPart,
              decoration: const InputDecoration(labelText: '부위'),
              items: [
                for (final part in parts)
                  DropdownMenuItem(value: part, child: Text(part)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPart = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveExercise, child: const Text('추가')),
          ],
        ),
      ),
    );
  }
}
