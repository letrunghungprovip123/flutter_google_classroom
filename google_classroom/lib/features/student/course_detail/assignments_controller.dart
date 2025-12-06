import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/assignment_model.dart';
import '../../../core/network/dio_client.dart';

final courseAssignmentsProvider =
    FutureProvider.family<List<AssignmentModel>, int>((ref, courseId) async {
      final dio = DioClient.instance.dio;

      final res = await dio.get(
        "/assignments",
        queryParameters: {"courseId": courseId},
      );

      final raw = res.data["data"] as List;
      return raw.map((json) => AssignmentModel.fromJson(json)).toList();
    });

final createAssignmentProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      payload,
    ) async {
      final dio = DioClient.instance.dio;

      final form = FormData.fromMap({
        "course_id": payload["course_id"],
        "title": payload["title"],
        "description": payload["description"],
        "start_date": payload["start_date"],
        "deadline": payload["deadline"],
        "late_deadline": payload["late_deadline"],
        "allow_late": payload["allow_late"].toString(),
        "max_attempts": payload["max_attempts"],
        "files": [...(payload["files"] as List<MultipartFile>)],
      });

      final res = await dio.post('/assignments', data: form);
      return res.data;
    });

final assignmentDetailProvider = FutureProvider.family<AssignmentModel, int>((
  ref,
  id,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/assignments/$id");
  return AssignmentModel.fromJson(res.data["data"]);
});

/// =======================================
/// DELETE Assignment
/// DELETE /assignments/:id
/// =======================================
final deleteAssignmentProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, int>((ref, assignmentId) async {
      final dio = DioClient.instance.dio;

      final res = await dio.delete("/assignments/$assignmentId");
      return res.data;
    });

final updateAssignmentProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      payload,
    ) async {
      final dio = DioClient.instance.dio;

      final id = payload["id"];
      payload.remove("id"); // quan trọng ⚠️

      final form = FormData.fromMap({
        ...payload,
        "allow_late": payload["allow_late"].toString(),
      });

      final res = await dio.patch("/assignments/$id", data: form);
      return res.data;
    });
