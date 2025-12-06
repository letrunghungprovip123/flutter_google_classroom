import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// =======================================================
/// LẤY DANH SÁCH MATERIAL THEO COURSE
/// GET /materials?courseId=xxx
/// =======================================================
final materialsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  courseId,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get(
    "/materials",
    queryParameters: {"courseId": courseId},
  );

  return res.data["data"] as List<dynamic>? ?? [];
});

/// =======================================================
/// LẤY CHI TIẾT 1 MATERIAL
/// GET /materials/:id
/// =======================================================
final materialDetailProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, materialId) async {
    final dio = DioClient.instance.dio;

    final res = await dio.get("/materials/$materialId");

    return res.data["data"] as Map<String, dynamic>;
  },
);


final createMaterialProvider = FutureProvider.family((
  ref,
  Map<String, dynamic> payload,
) async {
  final dio = DioClient.instance.dio;

  final formData = FormData.fromMap(payload);

  final res = await dio.post('/materials', data: formData);

  return res.data;
});

/// =======================================================
/// SERVICE: CRUD MATERIAL
/// =======================================================
class MaterialService {
  /// -----------------------------
  /// 🟦 Tạo tài liệu
  /// POST /materials
  /// -----------------------------
  static Future<Map<String, dynamic>> createMaterial({
    required int courseId,
    required String title,
    required String description,
    List<MultipartFile>? files,
  }) async {
    final dio = DioClient.instance.dio;

    final formData = FormData.fromMap({
      "course_id": courseId,
      "title": title,
      "description": description,
      "files": files,
    });

    final res = await dio.post("/materials", data: formData);

    return res.data;
  }

  /// -----------------------------
  /// 🟧 Lấy danh sách tài liệu theo khóa học
  /// GET /materials?courseId=xxx
  /// -----------------------------
  static Future<List<dynamic>> fetchMaterials(int courseId) async {
    final dio = DioClient.instance.dio;

    final res = await dio.get(
      "/materials",
      queryParameters: {"courseId": courseId},
    );

    return res.data["data"] as List<dynamic>? ?? [];
  }

  /// -----------------------------
  /// 🟩 Lấy chi tiết tài liệu
  /// GET /materials/:id
  /// -----------------------------
  static Future<Map<String, dynamic>> fetchMaterialDetail(int id) async {
    final dio = DioClient.instance.dio;

    final res = await dio.get("/materials/$id");

    return res.data["data"] as Map<String, dynamic>;
  }

  /// -----------------------------
  /// 🟥 Xoá tài liệu
  /// DELETE /materials/:id
  /// -----------------------------
  static Future<Map<String, dynamic>> deleteMaterial(int id) async {
    final dio = DioClient.instance.dio;

    final res = await dio.delete("/materials/$id");

    return res.data;
  }
}
