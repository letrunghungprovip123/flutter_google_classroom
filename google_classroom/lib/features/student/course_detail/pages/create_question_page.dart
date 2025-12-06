import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void addQuestion() {
    setState(() => questions.add(_QuestionFormModel()));
  }

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
          const SnackBar(content: Text("Vui lòng điền đầy đủ tất cả trường")),
        );
        return;
      }

      payload.add({
        "course_id": widget.courseId,
        "question_text": q.question.text.trim(),
        "option_a": q.a.text.trim(),
        "option_b": q.b.text.trim(),
        "option_c": q.c.text.trim(),
        "option_d": q.d.text.trim(),
        "correct_option": q.correct,
        "difficulty": q.difficulty,
      });
    }

    setState(() => isSubmitting = true);

    try {
      await ref.read(createQuestionsProvider(payload).future);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tạo câu hỏi thành công!")));

      Navigator.pop(context, true); // 🎯 chỉ pop khi thành công
    } catch (err) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString().replaceAll("Exception:", "").trim()),
        ),
      );
    }

    if (mounted) setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
        title: const Text(
          "Create Questions",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            ...questions.asMap().entries.map((entry) {
              int i = entry.key;
              var q = entry.value;

              return _buildQuestionForm(i, q);
            }),

            ElevatedButton.icon(
              onPressed: addQuestion,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: const Text(
                "Thêm câu hỏi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // xanh lá dịu
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4, // bóng nhẹ
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 52),
          ),
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Tạo câu hỏi",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildQuestionForm(int i, _QuestionFormModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
              Text(
                "Câu hỏi ${i + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeQuestion(i),
                ),
            ],
          ),
          const SizedBox(height: 4),
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

          _answerDropdownRow(q),
        ],
      ),
    );
  }

  Widget _answerDropdownRow(_QuestionFormModel q) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: q.correct,
            decoration: _dropDeco("Đáp án đúng"),
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: "A", child: Text("A")),
              DropdownMenuItem(value: "B", child: Text("B")),
              DropdownMenuItem(value: "C", child: Text("C")),
              DropdownMenuItem(value: "D", child: Text("D")),
            ],
            onChanged: (v) => setState(() => q.correct = v!),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: q.difficulty,
            decoration: _dropDeco("Độ khó"),
            dropdownColor: Colors.black,
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

  InputDecoration _dropDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return TextField(
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
}

class _QuestionFormModel {
  final question = TextEditingController();
  final a = TextEditingController();
  final b = TextEditingController();
  final c = TextEditingController();
  final d = TextEditingController();

  String correct = "A";
  String difficulty = "easy";

  bool isValid() {
    return question.text.trim().isNotEmpty &&
        a.text.trim().isNotEmpty &&
        b.text.trim().isNotEmpty &&
        c.text.trim().isNotEmpty &&
        d.text.trim().isNotEmpty;
  }
}
