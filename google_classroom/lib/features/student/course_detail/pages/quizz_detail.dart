import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../quiz_attemp_controller.dart';
import '../quizz_controller.dart';
import 'quiz_attempt_page.dart';

class QuizDetailPage extends ConsumerWidget {
  final int quizId;

  const QuizDetailPage({super.key, required this.quizId});

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuiz = ref.watch(quizDetailProvider(quizId));

    return asyncQuiz.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        appBar: _appBar(context),
        body: Center(
          child: Text(
            "Lỗi tải quiz: $e",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (quiz) {
        final instructor = quiz["users"]?["full_name"] ?? "Giảng viên";
        final openTime = _fmtDate(quiz["open_time"]);
        final closeTime = _fmtDate(quiz["close_time"]);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _appBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  quiz["title"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 20),

                // INFO CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.person, "Giảng viên", instructor),
                      const SizedBox(height: 12),

                      _infoRow(Icons.lock_clock, "Mở lúc", openTime),
                      const SizedBox(height: 12),

                      _infoRow(Icons.timer_off, "Đóng lúc", closeTime),
                      const SizedBox(height: 12),

                      _infoRow(
                        Icons.access_alarm,
                        "Thời gian làm bài",
                        "${quiz["duration_minutes"]} phút",
                      ),
                      const SizedBox(height: 12),

                      _infoRow(
                        Icons.repeat,
                        "Số lần làm tối đa",
                        "${quiz["max_attempts"]} lần",
                      ),
                      const SizedBox(height: 12),

                      const Divider(color: Colors.white24, height: 30),

                      const Text(
                        "Số lượng câu hỏi theo độ khó:",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 10),

                      _infoRow(
                        Icons.looks_one,
                        "Dễ",
                        "${quiz["random_easy"]} câu",
                      ),
                      const SizedBox(height: 8),

                      _infoRow(
                        Icons.looks_two,
                        "Trung bình",
                        "${quiz["random_medium"]} câu",
                      ),
                      const SizedBox(height: 8),

                      _infoRow(
                        Icons.looks_3,
                        "Khó",
                        "${quiz["random_hard"]} câu",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // START BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final result = await QuizAttemptService.startAttempt(
                          quizId: quiz["id"],
                        );

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizAttemptPage(
                              attemptId: result["attempt_id"],
                              questions: result["questions"],
                              durationMinutes: quiz["duration_minutes"],
                            ),
                          ),
                        );
                      } on DioException catch (e) {
                        final msg =
                            e.response?.data?["message"] ??
                            "Lỗi server, vui lòng thử lại";

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi không xác định: $e")),
                        );
                      }
                    },
                    child: const Text(
                      "Start Quiz",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // WIDGET: APP BAR
  // ============================================================
  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: const Text("Quiz Detail", style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1E1E1E),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // ============================================================
  // WIDGET: INFO ROW
  // ============================================================
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
