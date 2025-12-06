import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// ===============================
/// PROVIDER: Lấy danh sách quiz theo courseId
/// GET /quizzes?courseId=xxx
/// ===============================
final quizzesProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  courseId,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get(
    "/quizzes",
    queryParameters: {"courseId": courseId},
  );

  final data = res.data["data"] as List? ?? [];
  return data;
});

final quizDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  quizId,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/quizzes/$quizId");

  return res.data["data"] as Map<String, dynamic>;
});

// ==============================
// QUESTION BANK PROVIDER
// GET /quizzes/question-bank?courseId=xx
// ==============================

final questionBankProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  courseId,
) async {
  try {
    final dio = DioClient.instance.dio;
    final res = await dio.get(
      "/quizzes/question-bank",
      queryParameters: {"courseId": courseId},
    );
    return res.data["data"] ?? [];
  } catch (e) {
    throw Exception("Load question bank failed: $e");
  }
});

// CREATE MULTIPLE QUESTIONS
final createQuestionsProvider =
    FutureProvider.family<void, List<Map<String, dynamic>>>((
      ref,
      payload,
    ) async {
      final dio = DioClient.instance.dio;
      try {
        await dio.post("/quizzes/question-bank", data: payload);
      } catch (e) {
        if (e is DioException && e.response?.data != null) {
          throw Exception(e.response!.data["message"]);
        }
        throw Exception("Create failed");
      }
    });

// DELETE {DELETE /quizzes/question-bank/:id}
final deleteQuestionProvider = FutureProvider.family<void, int>((
  ref,
  id,
) async {
  final dio = DioClient.instance.dio;
  try {
    await dio.delete("/quizzes/question-bank/$id");
  } catch (e) {
    throw Exception("Delete failed");
  }
});

/// ===============================
/// SERVICE: Quản lý Quiz (tạo / sửa / xoá)
/// ===============================
class QuizService {
  /// -----------------------------
  /// Tạo quiz
  /// POST /quizzes
  /// -----------------------------
  static Future<Map<String, dynamic>> createQuiz({
    required int courseId,
    required String title,
    String? openTime,
    String? closeTime,
    int? durationMinutes,
    int? maxAttempts,
    int? randomEasy,
    int? randomMedium,
    int? randomHard,
  }) async {
    final dio = DioClient.instance.dio;

    final res = await dio.post(
      "/quizzes",
      data: {
        "course_id": courseId,
        // instructor_id không gửi → backend tự lấy từ token
        "title": title,
        if (openTime != null) "open_time": openTime,
        if (closeTime != null) "close_time": closeTime,
        if (durationMinutes != null) "duration_minutes": durationMinutes,
        if (maxAttempts != null) "max_attempts": maxAttempts,
        if (randomEasy != null) "random_easy": randomEasy,
        if (randomMedium != null) "random_medium": randomMedium,
        if (randomHard != null) "random_hard": randomHard,
      },
    );

    return res.data;
  }


/// -----------------------------
  /// Cập nhật quiz
  /// PATCH /quizzes/:id
  /// -----------------------------
  static Future<Map<String, dynamic>> updateQuiz({
    required int quizId,
    String? title,
    String? openTime,
    String? closeTime,
    int? durationMinutes,
    int? maxAttempts,
    int? randomEasy,
    int? randomMedium,
    int? randomHard,
  }) async {
    final dio = DioClient.instance.dio;

    // 🧠 Chỉ thêm field nào có giá trị → tránh override null lên DB
    final Map<String, dynamic> data = {};

    if (title != null) data["title"] = title;
    if (openTime != null) data["open_time"] = openTime;
    if (closeTime != null) data["close_time"] = closeTime;
    if (durationMinutes != null) data["duration_minutes"] = durationMinutes;
    if (maxAttempts != null) data["max_attempts"] = maxAttempts;
    if (randomEasy != null) data["random_easy"] = randomEasy;
    if (randomMedium != null) data["random_medium"] = randomMedium;
    if (randomHard != null) data["random_hard"] = randomHard;

    final res = await dio.patch("/quizzes/$quizId", data: data);

    return res.data;
  }

  /// -----------------------------
  /// Xoá quiz
  /// DELETE /quizzes/:id
  /// -----------------------------
  static Future<Map<String, dynamic>> deleteQuiz(int quizId) async {
    final dio = DioClient.instance.dio;

    final res = await dio.delete("/quizzes/$quizId");

    return res.data;
  }
}
