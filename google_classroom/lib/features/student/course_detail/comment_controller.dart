import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// =======================================
/// PROVIDER: Lấy danh sách comment theo announcement
/// GET /announcements/:id/comments
/// =======================================
final commentsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  announcementId,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/announcements/$announcementId/comments");

  final data = res.data["data"] as List? ?? [];

  return data;
});

/// =======================================
/// SERVICE: Quản lý comment (create, delete)
/// =======================================
class CommentService {
  /// -----------------------------
  /// 🟦 Tạo comment
  /// POST /announcements/:id/comments
  /// -----------------------------
  static Future<Map<String, dynamic>> createComment({
    required int announcementId,
    required String content,
  }) async {
    final dio = DioClient.instance.dio;

    final res = await dio.post(
      "/announcements/$announcementId/comments",
      data: {"content": content},
    );

    return res.data;
  }

  /// -----------------------------
  /// 🟥 Xoá comment
  /// DELETE /announcements/comments/:commentId
  /// -----------------------------
  static Future<Map<String, dynamic>> deleteComment(int commentId) async {
    final dio = DioClient.instance.dio;

    final res = await dio.delete("/announcements/comments/$commentId");

    return res.data;
  }
}
