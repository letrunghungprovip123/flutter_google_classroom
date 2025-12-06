import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './../course_detail_controller.dart';
import '../quizz_controller.dart';

class CreateQuestionPage extends ConsumerStatefulWidget {
  final int courseId;
  const CreateQuestionPage({super.key, required this.courseId});

  @override
  ConsumerState<CreateQuestionPage> createState() => _CreateQuestionPageState();
}

class _CreateQuestionPageState extends ConsumerState<CreateQuestionPage> {
  List<_QuestionFormModel> questions = [_QuestionFormModel()];
  bool isSubmitting = false;

  // 🔥 input AI modal
  final easyCtrl = TextEditingController(text: "2");
  final mediumCtrl = TextEditingController(text: "1");
  final hardCtrl = TextEditingController(text: "1");

  void addQuestion() => setState(() => questions.add(_QuestionFormModel()));

  void removeQuestion(int i) {
    if (questions.length > 1) {
      setState(() => questions.removeAt(i));
    }
  }

  Future<void> submit() async {
    final payload = <Map<String, dynamic>>[];

    for (var q in questions) {
      if (!q.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng điền đủ thông tin!")),
        );
        return;
      }
      payload.add(q.toJson(widget.courseId));
    }

    setState(() => isSubmitting = true);
    try {
      await ref.read(createQuestionsProvider(payload).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Thành công!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    if (mounted) setState(() => isSubmitting = false);
  }

  Future<void> openAiDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(builder: (context, ref, _) {
          final courseState = ref.watch(courseDetailProvider(widget.courseId));
          print(widget.courseId);
          return courseState.when(
            loading: () => SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (err, _) => SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  "Lỗi tải môn học!",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
            data: (course) {
              final subject = course["name"] ?? "Unknown Subject";

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create AI Quiz",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _aiInput("Easy", easyCtrl),
                    const SizedBox(height: 10),
                    _aiInput("Medium", mediumCtrl),
                    const SizedBox(height: 10),
                    _aiInput("Hard", hardCtrl),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // đóng bottom sheet
                        _generateAI(subject); // gọi AI
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Generate"),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  Future<void> _generateAI(String subject) async {
    setState(() => isSubmitting = true);

    final payload = {
      "subjectName": subject,
      "courseId": widget.courseId,
      "easyCount": int.parse(easyCtrl.text),
      "mediumCount": int.parse(mediumCtrl.text),
      "hardCount": int.parse(hardCtrl.text),
    };

    try {
      final res = await ref.read(
        generateAiQuizProvider(payload).future,
      );

      final List<dynamic> list = res as List<dynamic>;

      print("list nè : $list");
      setState(() {
        questions.addAll(
          list.map((q) => _QuestionFormModel.fromJson(q)).toList(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI Generate thành công!")),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI generate failed: $e")),
      );
    }

    setState(() => isSubmitting = false);
  }

  Widget _aiInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "$label questions",
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Create Questions",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: openAiDialog,
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            tooltip: "Generate by AI",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        child: Column(
          children: [
            ...questions.asMap().entries.map((e) {
              return _buildQuestionForm(e.key, e.value);
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: addQuestion,
              icon: const Icon(Icons.add),
              label: const Text("Thêm câu hỏi"),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50)),
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Tạo câu hỏi"),
        ),
      ),
    );
  }

  Widget _buildQuestionForm(int i, _QuestionFormModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Câu hỏi ${i + 1}",
                  style: const TextStyle(color: Colors.white)),
              const Spacer(),
              if (questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeQuestion(i),
                )
            ],
          ),
          _input("Nội dung câu hỏi", q.question),
          const SizedBox(height: 10),
          _input("A", q.a),
          const SizedBox(height: 10),
          _input("B", q.b),
          const SizedBox(height: 10),
          _input("C", q.c),
          const SizedBox(height: 10),
          _input("D", q.d),
          const SizedBox(height: 14),
          _dropdowns(q),
        ],
      ),
    );
  }

  Widget _dropdowns(_QuestionFormModel q) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: q.correct,
            dropdownColor: Colors.black,
            decoration: _dropDeco("Đáp án"),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: "a", child: Text("A")),
              DropdownMenuItem(value: "b", child: Text("B")),
              DropdownMenuItem(value: "c", child: Text("C")),
              DropdownMenuItem(value: "d", child: Text("D")),
            ],
            onChanged: (v) => setState(() => q.correct = v!),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: q.difficulty,
            dropdownColor: Colors.black,
            decoration: _dropDeco("Độ khó"),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: "easy", child: Text("Easy")),
              DropdownMenuItem(value: "medium", child: Text("Medium")),
              DropdownMenuItem(value: "hard", child: Text("Hard")),
            ],
            onChanged: (v) => setState(() => q.difficulty = v!),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropDeco(String title) => InputDecoration(
        labelText: title,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      );

  Widget _input(String label, TextEditingController ctrl) => TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
      );
}

class _QuestionFormModel {
  TextEditingController question = TextEditingController();
  TextEditingController a = TextEditingController();
  TextEditingController b = TextEditingController();
  TextEditingController c = TextEditingController();
  TextEditingController d = TextEditingController();

  String correct = "a";
  String difficulty = "easy";

  bool isValid() =>
      question.text.isNotEmpty &&
      a.text.isNotEmpty &&
      b.text.isNotEmpty &&
      c.text.isNotEmpty &&
      d.text.isNotEmpty;

  Map<String, dynamic> toJson(int courseId) => {
        "course_id": courseId,
        "question_text": question.text.trim(),
        "option_a": a.text.trim(),
        "option_b": b.text.trim(),
        "option_c": c.text.trim(),
        "option_d": d.text.trim(),
        "correct_option": correct,
        "difficulty": difficulty,
      };

  _QuestionFormModel();

  factory _QuestionFormModel.fromJson(Map<String, dynamic> json) {
    final model = _QuestionFormModel();
    model.question.text = json["question_text"];
    model.a.text = json["option_a"];
    model.b.text = json["option_b"];
    model.c.text = json["option_c"];
    model.d.text = json["option_d"];
    model.correct = json["correct_option"];
    model.difficulty = json["difficulty"];
    return model;
  }
}
