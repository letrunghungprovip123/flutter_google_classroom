import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../quizz_controller.dart';

class CreateQuizPage extends ConsumerStatefulWidget {
  final int courseId;
  final int? quizId; // 🔥 Optional => edit mode

  const CreateQuizPage({super.key, required this.courseId, this.quizId});

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage> {
  final _titleCtrl = TextEditingController();
  final _easyCtrl = TextEditingController(text: "0");
  final _mediumCtrl = TextEditingController(text: "0");
  final _hardCtrl = TextEditingController(text: "0");

  DateTime? openTime;
  DateTime? closeTime;
  int duration = 15;
  bool isLoading = false;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.quizId != null;
    if (isEdit) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ref.read(quizDetailProvider(widget.quizId!).future);

      _titleCtrl.text = data["title"] ?? "";
      duration = data["duration_minutes"] ?? 15;
      _easyCtrl.text = "${data["random_easy"] ?? 0}";
      _mediumCtrl.text = "${data["random_medium"] ?? 0}";
      _hardCtrl.text = "${data["random_hard"] ?? 0}";
      openTime = data["open_time"] != null
          ? DateTime.parse(data["open_time"])
          : null;
      closeTime = data["close_time"] != null
          ? DateTime.parse(data["close_time"])
          : null;

      setState(() {});
    } catch (e) {
      _msg("Load quiz failed ❌");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isEdit ? "Edit Quiz" : "Create Quiz",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF121212),

      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _inputText("Quiz Title", _titleCtrl),

              const SizedBox(height: 16),
              _datePicker("Open Time", openTime, (d) {
                setState(() => openTime = d);
              }),

              const SizedBox(height: 12),
              _datePicker("Close Time", closeTime, (d) {
                setState(() => closeTime = d);
              }),

              const SizedBox(height: 22),
              const Text(
                "Quiz Duration (minutes)",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                dropdownColor: const Color(0xFF1E1E1E),
                value: duration,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
                items: const [15, 30, 45, 60]
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text("$e minutes")),
                    )
                    .toList(),
                onChanged: (v) => setState(() => duration = v ?? 15),
              ),

              const SizedBox(height: 24),
              const Text(
                "Random Questions",
                style: TextStyle(color: Colors.greenAccent, fontSize: 16),
              ),

              const SizedBox(height: 10),
              _inputNumber("Easy", _easyCtrl),
              const SizedBox(height: 10),
              _inputNumber("Medium", _mediumCtrl),
              const SizedBox(height: 10),
              _inputNumber("Hard", _hardCtrl),

              const SizedBox(height: 100),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? "Save Changes" : "Create Quiz",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _msg("Title is required!");
      return;
    }
    if (openTime == null || closeTime == null) {
      _msg("Please select Open & Close time!");
      return;
    }
    if (!openTime!.isBefore(closeTime!)) {
      _msg("Open time must be before Close time!");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isEdit) {
        await QuizService.updateQuiz(
          quizId: widget.quizId!,
          title: _titleCtrl.text,
          openTime: openTime?.toIso8601String(),
          closeTime: closeTime?.toIso8601String(),
          durationMinutes: duration,
          randomEasy: int.tryParse(_easyCtrl.text),
          randomMedium: int.tryParse(_mediumCtrl.text),
          randomHard: int.tryParse(_hardCtrl.text),
        );
        _msg("Quiz updated successfully!");
      } else {
        await QuizService.createQuiz(
          courseId: widget.courseId,
          title: _titleCtrl.text.trim(),
          openTime: openTime!.toIso8601String(),
          closeTime: closeTime!.toIso8601String(),
          durationMinutes: duration,
          randomEasy: int.tryParse(_easyCtrl.text) ?? 0,
          randomMedium: int.tryParse(_mediumCtrl.text) ?? 0,
          randomHard: int.tryParse(_hardCtrl.text) ?? 0,
        );
        _msg("Quiz created successfully ");
      }

      Navigator.pop(context, true); // 🔥 Trigger refresh on parent page
    } catch (e) {
      _msg("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _datePicker(String label, DateTime? date, Function(DateTime) cb) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          initialDate: date ?? DateTime.now(),
          helpText: label,
        );
        if (picked != null) cb(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration(),
        child: Text(
          date == null ? label : "$label: ${date.toString().split(' ')[0]}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _inputText(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: label),
    );
  }

  Widget _inputNumber(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: "$label Questions"),
    );
  }

  InputDecoration _inputDecoration({String? label}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blueAccent),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  BoxDecoration _boxDecoration() => BoxDecoration(
    border: Border.all(color: Colors.white24),
    borderRadius: BorderRadius.circular(12),
  );

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.blueGrey),
    );
  }
}
