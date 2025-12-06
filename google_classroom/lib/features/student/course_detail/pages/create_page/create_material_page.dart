import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/network/dio_client.dart';
import '../../material_controller.dart';

class CreateMaterialPage extends ConsumerStatefulWidget {
  final int courseId;

  const CreateMaterialPage({super.key, required this.courseId});

  @override
  ConsumerState<CreateMaterialPage> createState() => _CreateMaterialPageState();
}

class _CreateMaterialPageState extends ConsumerState<CreateMaterialPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool isSubmitting = false;
  List<PlatformFile> selectedFiles = [];

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  // -----------------------------
  // PICK FILES (MOBILE + WEB)
  // -----------------------------
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb, // web cần bytes
      );

      if (result == null) return;

      final List<PlatformFile> validFiles = [];

      for (final f in result.files) {
        final size = f.size; // luôn có, kể cả web

        if (size > maxFileSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "File '${f.name}' vượt quá ${maxFileSizeBytes ~/ (1024 * 1024)}MB, đã bỏ qua.",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          continue;
        }

        validFiles.add(f);
      }

      if (validFiles.isEmpty) return;

      setState(() {
        selectedFiles.addAll(validFiles);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không chọn được file: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  // -----------------------------
  // PlatformFile -> MultipartFile
  // -----------------------------
  Future<MultipartFile> _toMultipart(PlatformFile f) async {
    // WEB: dùng bytes
    if (kIsWeb) {
      if (f.bytes == null) {
        throw Exception("File.bytes null trên Web cho file: ${f.name}");
      }
      return MultipartFile.fromBytes(f.bytes!, filename: f.name);
    }

    // MOBILE / DESKTOP: dùng path + File
    if (f.path == null) {
      throw Exception("File.path null trên Mobile/Desktop cho file: ${f.name}");
    }

    final file = File(f.path!);
    final length = await file.length();
    if (length > maxFileSizeBytes) {
      throw Exception(
        "File '${f.name}' vượt quá ${maxFileSizeBytes ~/ (1024 * 1024)}MB",
      );
    }

    return MultipartFile.fromFile(file.path, filename: f.name);
  }

  // -----------------------------
  // SUBMIT
  // -----------------------------
  Future<void> submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // convert files -> MultipartFile[]
      final files = await Future.wait(selectedFiles.map(_toMultipart));

      final payload = {
        "course_id": widget.courseId,
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "files": files,
      };

      await ref.read(createMaterialProvider(payload).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Material created!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // báo cho page ngoài reload
    } catch (e) {
      String message = "Unknown error";

      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data["message"] != null) {
          message = data["message"].toString();
        } else {
          message = e.message ?? message;
        }
      } else {
        message = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Material",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input("Title", _titleCtrl),
            const SizedBox(height: 16),

            _input("Description", _descCtrl, maxLines: 3),
            const SizedBox(height: 16),

            // FILE PICKER
            TextButton.icon(
              onPressed: isSubmitting ? null : pickFiles,
              icon: const Icon(Icons.attach_file, color: Colors.white),
              label: const Text(
                "Đính kèm tập tin",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),

            // DANH SÁCH FILE + NÚT XOÁ
            ...selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final f = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => removeFile(index),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1A1A1A),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Tạo Material",
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
