import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class StudentProfileService {
  /// ============================
  /// UPDATE PROFILE
  /// PATCH /auth
  /// ============================
static Future<Map<String, dynamic>> updateProfile({
    File? avatarFile,
    List<int>? avatarBytes,
    String? filename,
    String? email,
    String? oldPassword,
    String? newPassword,
  }) async {
    final dio = DioClient.instance.dio;
    final form = FormData();

    // ======================
    // (1) Avatar optional
    // ======================
    if (avatarBytes != null) {
      // --- Web upload bytes ---
      form.files.add(
        MapEntry(
          "file",
          MultipartFile.fromBytes(
            avatarBytes,
            filename: filename ?? "avatar.png",
          ),
        ),
      );
    } else if (avatarFile != null) {
      // --- Mobile/desktop upload file ---
      form.files.add(
        MapEntry(
          "file",
          await MultipartFile.fromFile(
            avatarFile.path,
            filename: avatarFile.path.split("/").last,
          ),
        ),
      );
    }

    // ======================
    // (2) Email optional
    // ======================
    if (email != null && email.isNotEmpty) {
      form.fields.add(MapEntry("email", email));
    }

    // ======================
    // (3) Change password optional
    // ======================
    if (newPassword != null && newPassword.isNotEmpty) {
      if (oldPassword == null || oldPassword.isEmpty) {
        throw Exception("Cần nhập mật khẩu cũ để đổi mật khẩu");
      }

      form.fields.add(MapEntry("old_password", oldPassword));
      form.fields.add(MapEntry("new_password", newPassword));
    }

    // ======================
    // (4) Call API
    // ======================
    final res = await dio.patch(
      "/auth",
      data: form,
      options: Options(contentType: "multipart/form-data"),
    );

    return res.data;
  }

}
