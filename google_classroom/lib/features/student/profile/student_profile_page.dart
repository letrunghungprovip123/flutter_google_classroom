// import 'dart:io';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/provider/user_controller.dart';
import './student_profile_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Provider quản lý trạng thái upload avatar
final isUploadingAvatarProvider = StateProvider<bool>((ref) => false);

/// Provider tránh mở ImagePicker 2 lần
final isPickingImageProvider = StateProvider<bool>((ref) => false);

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            "Lỗi tải thông tin: $err",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                "Không có dữ liệu người dùng",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final avatarUrl = user.avatarUrl;
          final isUploading = ref.watch(isUploadingAvatarProvider);
          final letter = user.fullName.isNotEmpty
              ? user.fullName[0].toUpperCase()
              : "U";

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              /// ======================
              /// AVATAR
              /// ======================
              Center(
                child: GestureDetector(
                  onTap: () => _pickAvatar(context, ref),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.green,
                        backgroundImage: (!isUploading && avatarUrl != null)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : avatarUrl == null
                            ? Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),

                      /// ICON EDIT — chỉ khi không upload
                      if (!isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _profileTile(
                icon: Icons.email,
                title: "Email",
                value: user.email,
              ),
              _profileTile(
                icon: Icons.person,
                title: "Full Name",
                value: user.fullName,
              ),
              _profileTile(
                icon: Icons.badge,
                title: "User ID",
                value: user.id.toString(),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openChangePasswordModal(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Đổi mật khẩu",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  /// ===================================================================
  /// PICK AVATAR — có khóa và loading
  /// ===================================================================
 Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final isPicking = ref.read(isPickingImageProvider);
    if (isPicking) return;

    ref.read(isPickingImageProvider.notifier).state = true;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      ref.read(isUploadingAvatarProvider.notifier).state = true;

      if (kIsWeb) {
        // WEB — upload bằng bytes
        final bytes = await pickedFile.readAsBytes();

        await StudentProfileService.updateProfile(
          avatarBytes: bytes,
          filename: pickedFile.name,
        );
      } else {
        // MOBILE — upload bằng file
        final file = File(pickedFile.path);

        final sizeMB = file.lengthSync() / (1024 * 1024);
        if (sizeMB > 5) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Ảnh phải nhỏ hơn 5MB")));
          return;
        }

        await StudentProfileService.updateProfile(avatarFile: file);
      }

      await ref.read(userControllerProvider.notifier).fetchUser();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật avatar thành công")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi đổi avatar: $e")));
    } finally {
      ref.read(isUploadingAvatarProvider.notifier).state = false;
      ref.read(isPickingImageProvider.notifier).state = false;
    }
  }


  /// ===================================================================
  /// POPUP CHANGE PASSWORD — có inline error
  /// ===================================================================
  void _openChangePasswordModal(BuildContext context, WidgetRef ref) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    String? oldPassError;
    String? newPassError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                "Đổi mật khẩu",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inputField(
                    "Mật khẩu cũ",
                    oldPassCtrl,
                    true,
                    errorText: oldPassError,
                  ),
                  const SizedBox(height: 10),
                  _inputField("Mật khẩu mới", newPassCtrl, true),
                  const SizedBox(height: 10),
                  _inputField(
                    "Nhập lại mật khẩu",
                    confirmCtrl,
                    true,
                    errorText: newPassError,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      oldPassError = null;
                      newPassError = null;
                    });

                    if (newPassCtrl.text != confirmCtrl.text) {
                      setState(
                        () => newPassError = "Mật khẩu nhập lại không khớp",
                      );
                      return;
                    }

                    try {
                      await StudentProfileService.updateProfile(
                        oldPassword: oldPassCtrl.text.trim(),
                        newPassword: newPassCtrl.text.trim(),
                      );

                      await ref
                          .read(userControllerProvider.notifier)
                          .fetchUser();

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đổi mật khẩu thành công"),
                        ),
                      );
                    } catch (e) {
                      if (e is DioException) {
                        final data = e.response?.data;

                        if (data is Map &&
                            data["message"] == "Mật khẩu cũ không chính xác") {
                          setState(
                            () => oldPassError = "Mật khẩu cũ không chính xác",
                          );
                          return;
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Có lỗi xảy ra, vui lòng thử lại"),
                        ),
                      );
                    }
                  },
                  child: const Text("Xác nhận"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ===================================================================
  /// INPUT FIELD
  /// ===================================================================
  Widget _inputField(
    String label,
    TextEditingController controller,
    bool isPassword, {
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  /// ===================================================================
  /// PROFILE TILE
  /// ===================================================================
  Widget _profileTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
