import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../shared/models/submission_model.dart';

/// =======================================
/// PROVIDER: Lấy bài nộp mới nhất của tôi
/// =======================================
///
/// Gọi API:
/// GET /submissions/my?assignmentId=xx
///
final mySubmissionProvider = FutureProvider.family<SubmissionModel?, int>((
  ref,
  assignmentId,
) async {
  final dio = DioClient.instance.dio;
  // print("ASSIGNMENT ID:$assignmentId");
  final res = await dio.get("/submissions/my/$assignmentId");

  final data = res.data["data"];
  if (data == null) return null;

  return SubmissionModel.fromJson(data);
});

/// Lấy danh sách submissions theo assignment
final submissionsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  assignmentId,
) async {
  final dio = DioClient.instance.dio;
  final res = await dio.get("/submissions/$assignmentId");
  return res.data["data"] ?? [];
});

/// =======================================
/// SERVICE: Nộp bài (gửi file + dto)
/// =======================================
class SubmissionService {
  static final dio = DioClient.instance.dio;

  static Future<Map<String, dynamic>> updateGrade({
    required int submissionId,
    required double grade,
  }) async {
    final res = await dio.put(
      "/submissions/$submissionId/grade",
      data: {"grade": grade},
    );
    return res.data;
  }

static Future<Map<String, dynamic>> createSubmission({
    required int assignmentId,
    required List<MultipartFile> files,
    required Function(int sent, int total)? onProgress,
  }) async {
    final dio = DioClient.instance.dio;

    final form = FormData.fromMap({
      "assignment_id": assignmentId,
      "files": files, // 👈 không tự tạo MultipartFile trong đây nữa
    });

    final res = await dio.post(
      "/submissions",
      data: form,
      onSendProgress: onProgress,
    );

    return res.data;
  }

}
