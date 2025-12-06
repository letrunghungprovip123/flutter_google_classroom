import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

/// =======================================================
/// 🔷 GET Conversation của Student (tự lấy từ JWT Token)
/// GET /students/chat/conversation
/// =======================================================
final conversationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/students/chat/conversation");
  return res.data["data"] ?? {};
});

/// =======================================================
/// 🔶 Instructor: Lấy danh sách tất cả cuộc trò chuyện
/// GET /students/chat/conversations
/// =======================================================
final conversationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/students/chat/conversations");
  return res.data["data"] ?? [];
});

/// =======================================================
/// 🔹 Student tạo conversation (nếu chưa có)
/// POST /students/chat/conversation
/// =======================================================
final createConversationProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((
      ref,
      payload,
    ) async {
      final dio = DioClient.instance.dio;

      final res = await dio.post(
        "/students/chat/conversation",
        data: payload.isEmpty ? null : payload,
      );

      return res.data;
    });

/// =======================================================
/// 🟦 Lấy danh sách tin nhắn trong 1 conversation
/// GET /students/chat/:conversationId/messages
/// =======================================================
final messagesProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  conversationId,
) async {
  final dio = DioClient.instance.dio;

  final res = await dio.get("/students/chat/$conversationId/messages");

  return res.data["data"] as List<dynamic>? ?? [];
});

/// =======================================================
/// 🟩 Gửi tin nhắn (có thể có nhiều file)
/// POST /students/chat/send
/// =======================================================
class MessageService {
  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String? content,
    List<MultipartFile>? files,
  }) async {
    final dio = DioClient.instance.dio;

    final formData = FormData.fromMap({
      "conversationId": conversationId,
      "content": content,
      if (files != null && files.isNotEmpty) "files": files,
    });

    final res = await dio.post("/students/chat/send", data: formData);

    return res.data;
  }

  /// ===================================================
  /// 🟧 Đánh dấu tất cả tin nhắn trong conversation là read
  /// PATCH /students/chat/:conversationId/mark-read
  /// ===================================================
  static Future<Map<String, dynamic>> markRead(int conversationId) async {
    final dio = DioClient.instance.dio;

    final res = await dio.patch("/students/chat/$conversationId/mark-read");

    return res.data;
  }
}
