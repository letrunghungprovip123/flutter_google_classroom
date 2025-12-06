import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_classroom/features/student/course_detail/pages/quiz_result_page.dart';
import '../quiz_attemp_controller.dart';

class QuizAttemptPage extends StatefulWidget {
  final int attemptId;
  final List<dynamic> questions;
  final int durationMinutes;

  const QuizAttemptPage({
    super.key,
    required this.attemptId,
    required this.questions,
    required this.durationMinutes,
  });

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  int currentIndex = 0;
  late int remainingSeconds;

  final Map<int, String> answers = {}; // questionId -> option
  Timer? timer;
  final PageController pageCtrl = PageController();

  @override
  void initState() {
    super.initState();

    remainingSeconds = widget.durationMinutes * 60;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds == 0) {
        _submitQuiz(auto: true);
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pageCtrl.dispose();
    super.dispose();
  }

  String _timeString() {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _chooseAnswer(int questionId, String choice) {
    setState(() {
      answers[questionId] = choice;
    });
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    timer?.cancel();

    if (!auto) {
      final ok = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Nộp bài?"),
          content: const Text("Bạn có chắc muốn nộp bài không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Nộp bài"),
            ),
          ],
        ),
      );

      if (ok != true) return;
    }

    final payload = answers.entries.map((e) {
      return {"question_id": e.key, "selected_option": e.value};
    }).toList();

    try {
      final result = await QuizAttemptService.submitQuiz(
        attemptId: widget.attemptId,
        answers: payload,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            score: result["score"],
            correct: result["correct"],
            total: result["total"],
            attemptData: result["data"],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nộp bài thất bại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final current = widget.questions[currentIndex];

    return WillPopScope(
      onWillPop: () async {
        final exit = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Không thể thoát"),
            content: const Text(
              "Bạn đang làm bài. Thoát ra sẽ nộp bài ngay lập tức.\nBạn có chắc muốn thoát không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Tiếp tục làm"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Thoát"),
              ),
            ],
          ),
        );

        if (exit == true) {
          _submitQuiz(auto: true);
        }

        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          automaticallyImplyLeading: false, // Ẩn nút back
          title: Text(
            "Câu ${currentIndex + 1} / $total",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _timeString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        body: PageView.builder(
          controller: pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.questions.length,
          itemBuilder: (_, i) {
            final q = widget.questions[i];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q["text"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _choiceTile(q, "a", q["a"]),
                  _choiceTile(q, "b", q["b"]),
                  _choiceTile(q, "c", q["c"]),
                  _choiceTile(q, "d", q["d"]),
                ],
              ),
            );
          },
        ),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF1E1E1E),
          child: Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                      setState(() => currentIndex--);
                    },
                    child: const Text(
                      "Trước đó",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              if (currentIndex > 0) const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (currentIndex == total - 1) {
                      _submitQuiz();
                    } else {
                      pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                      setState(() => currentIndex++);
                    }
                  },
                  child: Text(
                    currentIndex == total - 1 ? "Nộp bài" : "Tiếp theo",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceTile(dynamic q, String key, String text) {
    final selected = answers[q["id"]] == key;

    return GestureDetector(
      onTap: () => _chooseAnswer(q["id"], key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "$key) $text",
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
