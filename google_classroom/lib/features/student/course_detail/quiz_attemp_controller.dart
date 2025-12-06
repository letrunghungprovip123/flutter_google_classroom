import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// =======================================================
/// PROVIDER: Start quiz attempt
/// POST /quiz-attempts
/// Only send quizId, backend lấy student từ token
/// =======================================================
final startQuizAttemptProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, quizId) async {
      final dio = DioClient.instance.dio;

      final res = await dio.post("/quiz-attempts", data: {"quizId": quizId});

      return res.data; // {"message": "...", "data": {...}}
    });

/// =======================================================
/// SERVICE: Dùng gọi trực tiếp khi bấm Start Quiz
/// =======================================================
class QuizAttemptService {
  /// -----------------------------
  /// 🟦 Start Attempt
  /// POST /quiz-attempts
  /// -----------------------------
  static Future<Map<String, dynamic>> startAttempt({
    required int quizId,
  }) async {
    final dio = DioClient.instance.dio;
    final res = await dio.post("/quiz-attempts", data: {"quiz_id": quizId});

    return res.data;
  }

  static Future<Map<String, dynamic>> submitQuiz({
    required int attemptId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final dio = DioClient.instance.dio;

    final res = await dio.put(
      "/quiz-attempts/$attemptId/submit",
      data: {"attempt_id": attemptId, "answers": answers},
    );

    return res.data;
  }
}
