import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_classroom/core/network/dio_client.dart';

import '../../../core/network/dio_client.dart';

/// =======================================================
/// PROVIDER: Lấy danh sách thông báo
/// GET /notifications/student
/// =======================================================
final notificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/notifications/student");

  return res.data["data"] as List<dynamic>? ?? [];
});

/// =======================================================
/// SERVICE: Notification Service
/// =======================================================
class NotificationService {
  /// ----------------------------------------------------
  /// 🟦 Lấy danh sách thông báo
  /// GET /notifications/student
  /// ----------------------------------------------------
  static Future<List<dynamic>> fetchNotifications() async {
    final dio = DioClient.instance.dio;

    final res = await dio.get("/notifications/student");
    print(res.data["data"]);
    return res.data["data"] as List<dynamic>? ?? [];
  }

  /// ----------------------------------------------------
  /// 🟩 Đánh dấu một thông báo là đã đọc
  /// PUT /notifications/:id/read
  /// ----------------------------------------------------
  static Future<Map<String, dynamic>> markAsRead(int id) async {
    final dio = DioClient.instance.dio;

    final res = await dio.put("/notifications/$id/read");

    return res.data;
  }

  /// ----------------------------------------------------
  /// 🟧 Đánh dấu tất cả là đã đọc
  /// PUT /notifications/read-all
  /// (nếu bạn cần sau này)
  /// ----------------------------------------------------
  static Future<Map<String, dynamic>> markAllAsRead() async {
    final dio = DioClient.instance.dio;

    final res = await dio.put("/notifications/read-all");

    return res.data;
  }
}
