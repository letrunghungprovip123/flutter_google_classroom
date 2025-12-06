import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../shared/models/course_model.dart';
import 'course_backgrounds.dart';

/// 🔥 CHỈ LOAD COURSE KHI CÓ semesterCode
final studentCoursesProvider =
    FutureProvider.family<List<CourseModel>, String?>((
      ref,
      semesterCode,
    ) async {
      if (semesterCode == null) return []; // Không gọi API khi chưa chọn học kỳ
      // print("Semester nè: $semesterCode");
      final dio = DioClient.instance.dio;

      final res = await dio.get(
        "/courses/student-courses",
        queryParameters: {"semesterCode": semesterCode},
      );

      final data = res.data["data"] as List;
      final random = Random();

      return data.map((json) {
        final bg = courseBackgrounds[random.nextInt(courseBackgrounds.length)];
        return CourseModel.fromJson(json, bg);
      }).toList();
    });

final instructorCoursesProvider =
    FutureProvider.family<List<CourseModel>, int?>((ref, semesterId) async {
      if (semesterId == null) return []; // chưa chọn học kỳ

      // print("Instructor semesterId nè: $semesterId");

      final dio = DioClient.instance.dio;

      final res = await dio.get(
        "/courses",
        queryParameters: {"semesterId": semesterId},
      );

      final data = res.data["data"] as List;
      final random = Random();

      return data.map((json) {
        final bg = courseBackgrounds[random.nextInt(courseBackgrounds.length)];
        return CourseModel.fromJson(json, bg);
      }).toList();
    });


final createCourseProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      payload,
    ) async {
      final dio = DioClient.instance.dio;

      final res = await dio.post(
        "/courses",
        data: payload, // { name, code, semester_id, sessions, groups: [] }
      );

      return res.data;
    });

/// 🔥 LOAD DANH SÁCH HỌC KỲ
final semestersProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await DioClient.instance.dio.get("/semesters");
  return res.data["data"] as List;
});


/// =======================================
/// 🟩 CREATE SEMESTER
/// POST /semesters
/// =======================================
class SemesterService {
  static Future<Map<String, dynamic>> create({
    required String code,
    required String name,
    String? startDate, // format: yyyy-MM-dd
    String? endDate,
  }) async {
    final dio = DioClient.instance.dio;

    final res = await dio.post(
      "/semesters",
      data: {
        "code": code,
        "name": name,
        "start_date": startDate,
        "end_date": endDate,
      },
    );

    return res.data;
  }
}
