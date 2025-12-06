import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../material_controller.dart';

class MaterialDetailPage extends ConsumerStatefulWidget {
  final int materialId;

  const MaterialDetailPage({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends ConsumerState<MaterialDetailPage> {
  // Lưu trạng thái đang mở file cho từng attachment
  final Map<int, bool> _isOpening = {};

  // ---------------------------------------------------------
  // ICON PICKER
  // ---------------------------------------------------------
  IconData _pickFileIcon(String url) {
    final u = url.toLowerCase();

    if (u.endsWith(".pdf")) return Icons.picture_as_pdf;
    if (u.endsWith(".doc") || u.endsWith(".docx")) return Icons.description;
    if (u.endsWith(".xls") || u.endsWith(".xlsx")) {
      return Icons.grid_view_rounded;
    }
    if (u.endsWith(".ppt") || u.endsWith(".pptx")) return Icons.slideshow;

    if (u.endsWith(".jpg") ||
        u.endsWith(".jpeg") ||
        u.endsWith(".png") ||
        u.endsWith(".gif")) {
      return Icons.image;
    }

    if (u.endsWith(".zip") || u.endsWith(".rar") || u.endsWith(".7z")) {
      return Icons.archive;
    }

    return Icons.insert_drive_file;
  }

  // ---------------------------------------------------------
  // OPEN FILE WITH LOADING STATE
  // ---------------------------------------------------------
  Future<void> _openFile(String url, int id) async {
    setState(() {
      _isOpening[id] = true;
    });

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không mở được file")));
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isOpening[id] = false;
      });
    }
  }

  // ---------------------------------------------------------
  // DATE FORMATTER
  // ---------------------------------------------------------
  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final asyncMaterial = ref.watch(materialDetailProvider(widget.materialId));

    return asyncMaterial.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Chi tiết tài liệu",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            "Lỗi tải tài liệu: $e",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (material) => _buildContent(context, material),
    );
  }

  // ---------------------------------------------------------
  // MAIN CONTENT USING MATERIAL DATA
  // ---------------------------------------------------------
  Widget _buildContent(BuildContext context, Map<String, dynamic> material) {
    final title = material["title"] ?? "Tài liệu";
    final description = material["description"] ?? "";
    final createdAt = material["created_at"];
    final attachments = material["attachments"] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Chi tiết tài liệu",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== TITLE =====================
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ===================== DATE =====================
            if (createdAt != null)
              Text(
                "Đăng lúc: ${_fmtDate(createdAt)}",
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),

            const SizedBox(height: 20),

            // ===================== DESCRIPTION =====================
            if (description.trim().isNotEmpty)
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white24, thickness: 0.7),
            const SizedBox(height: 16),

            // ===================== ATTACHMENTS TITLE =====================
            const Text(
              "Tệp đính kèm",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // ===================== ATTACHMENT LIST =====================
            if (attachments.isEmpty)
              const Text(
                "Không có tệp đính kèm",
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),

            ...attachments.map((file) {
              final url = file["file_url"] ?? "";
              final rawName = (file["file_name"] ?? "").toString();
              final int id = file["id"];

              // Nếu file_name = "file" → fallback lấy từ url
              final name = rawName.isNotEmpty && rawName.toLowerCase() != "file"
                  ? rawName
                  : url.split("/").last;

              final isLoading = _isOpening[id] == true;

              return GestureDetector(
                onTap: () => _openFile(url, id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Loading icon hoặc file icon
                      isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.lightBlueAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _pickFileIcon(url),
                              color: Colors.lightBlueAccent,
                              size: 30,
                            ),

                      const SizedBox(width: 14),

                      // File Name hyperlink style
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.lightBlueAccent,
                          ),
                        ),
                      ),

                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
