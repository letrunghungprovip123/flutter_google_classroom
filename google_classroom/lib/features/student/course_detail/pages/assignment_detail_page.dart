import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/assignment_model.dart';
import '../submission_controller.dart';
import '../../../shared/models/submission_model.dart';
import '../assignments_controller.dart';
import 'dart:io' show File;
import 'package:dio/dio.dart' show DioError, DioException, MultipartFile;
import 'package:flutter/foundation.dart' show kIsWeb;

class AssignmentDetailPage extends ConsumerStatefulWidget {
  final int assignmentId;

  const AssignmentDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailPage> createState() =>
      _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends ConsumerState<AssignmentDetailPage> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // ⭐ trạng thái opening giống Material
  final Map<String, bool> _isOpeningFile = {};

  @override
  Widget build(BuildContext context) {
    final asyncAssignment = ref.watch(
      assignmentDetailProvider(widget.assignmentId),
    );

    return asyncAssignment.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (assignment) {
        final asyncMySub = ref.watch(mySubmissionProvider(assignment.id));

        return asyncMySub.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(context),
            body: Center(
              child: Text("Error: $e", style: TextStyle(color: Colors.red)),
            ),
          ),
          data: (mySubmission) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: _buildAppBar(context),
              bottomSheet: _buildSubmitButton(
                context,
                mySubmission,
                assignment,
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _buildHeader(assignment),
                  const SizedBox(height: 20),
                  _buildDeadline(assignment),
                  const SizedBox(height: 20),

                  /// ⭐ FILES GIỐNG MATERIAL STYLE
                  _buildAttachments(assignment),
                  const SizedBox(height: 20),

                  _buildSubmissionInfo(mySubmission, assignment),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // APP BAR
  // -------------------------------------------------------------
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      automaticallyImplyLeading: false,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER
  // -------------------------------------------------------------
  Widget _buildHeader(AssignmentModel assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assignment.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (assignment.description != null)
          Text(
            assignment.description!,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // DEADLINE
  // -------------------------------------------------------------
  Widget _buildDeadline(AssignmentModel assignment) {
    final deadline = assignment.deadline;
    final now = DateTime.now();
    final missing = deadline != null && now.isAfter(deadline);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              deadline == null ? "Không có ngày đến hạn" : _fmt(deadline),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Text(
            missing ? "Trễ hạn" : "Đang mở",
            style: TextStyle(
              color: missing ? Colors.red : Colors.greenAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ATTACHMENTS LIST ⭐⭐ (GIỐNG MATERIAL)
  // -------------------------------------------------------------
  Widget _buildAttachments(AssignmentModel a) {
    if (a.attachments.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tệp đính kèm",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 12),

        ...a.attachments.map((file) {
          final url = file.fileUrl;
          final fileName = file.fileName ?? "file";
          final idKey = "a-${file.fileUrl}";

          final isOpening = _isOpeningFile[idKey] == true;

          return GestureDetector(
            onTap: () => _openFile(url, idKey),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  isOpening
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.lightBlueAccent,
                          ),
                        )
                      : Icon(
                          _pickIcon(url),
                          color: Colors.lightBlueAccent,
                          size: 30,
                        ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      _extractName(url, fileName),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
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
    );
  }

  // -------------------------------------------------------------
  // OPEN FILE
  // -------------------------------------------------------------
  Future<void> _openFile(String url, String idKey) async {
    setState(() => _isOpeningFile[idKey] = true);

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không mở được file")));
    }

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _isOpeningFile[idKey] = false);
    }
  }

  // -------------------------------------------------------------
  // MY SUBMISSION
  // -------------------------------------------------------------
  Widget _buildSubmissionInfo(
    SubmissionModel? mySub,
    AssignmentModel assignment,
  ) {
    final attempts = mySub?.attemptNo ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bài nộp của bạn",
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 8),

          Text(
            "Số lần được nộp: ${assignment.maxAttempts}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),

          Text(
            "Đã nộp: $attempts lần",
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 12),

          if (_isUploading) ...[
            const Text(
              "Đang tải tệp lên...",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _uploadProgress == 0 ? null : _uploadProgress,
              color: Colors.greenAccent,
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 10),
          ],

          if (!_isUploading && mySub != null) _buildMyFiles(mySub),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FILES IN MY SUBMISSION ⭐⭐ (Giống Material)
  // -------------------------------------------------------------
  Widget _buildMyFiles(SubmissionModel sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tệp đã nộp:",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 10),

        ...sub.attachments.map((file) {
          final url = file.url;
          final idKey = "s-${file.url}";
          final isOpening = _isOpeningFile[idKey] == true;

          return GestureDetector(
            onTap: () => _openFile(url, idKey),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  isOpening
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.lightBlueAccent,
                          ),
                        )
                      : Icon(
                          _pickIcon(url),
                          color: Colors.lightBlueAccent,
                          size: 28,
                        ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      _extractName(url, file.name),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // SUBMIT FILE
  // -------------------------------------------------------------
  Widget _buildSubmitButton(
    BuildContext context,
    SubmissionModel? mySub,
    AssignmentModel assignment,
  ) {
    final canSubmit = (mySub?.attemptNo ?? 0) < assignment.maxAttempts;

    return Container(
      padding: const EdgeInsets.all(25),
      color: Colors.black,
      child: ElevatedButton(
        onPressed: canSubmit
            ? () => _openSubmitSheet(context, assignment.id)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Colors.blueAccent : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 119),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          canSubmit ? "+ Thêm bài nộp" : "Số lần nộp tối đa",
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FILE PICKER SHEET
  // -------------------------------------------------------------
  void _openSubmitSheet(BuildContext context, int assignmentId) {
    final parentContext = context;
    List<PlatformFile> selectedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity, // ⭐ FULL WIDTH
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: StatefulBuilder(
            builder: (context, modalSet) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Thêm bài nộp",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          withData: kIsWeb,
                        );

                        if (result != null) {
                          modalSet(() {
                            selectedFiles.addAll(result.files);
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file, color: Colors.white),
                      label: const Text(
                        "Chọn file",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (selectedFiles.isNotEmpty)
                      ...selectedFiles.map(
                        (file) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  file.name,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  modalSet(() {
                                    selectedFiles.remove(file);
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // màu nền NỔI BẬT
                        foregroundColor: Colors.white, // màu chữ
                        disabledBackgroundColor: Colors.grey, // khi disabled
                        disabledForegroundColor: Colors.white54, // khi disabled
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 60,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: selectedFiles.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(context);

                              setState(() {
                                _isUploading = true;
                                _uploadProgress = 0;
                              });

                              final filesMultipart = await Future.wait(
                                selectedFiles.map((file) async {
                                  const maxSize = 20 * 1024 * 1024;
                                  if (file.size > maxSize)
                                    throw Exception("File quá lớn (>20MB)");

                                  if (kIsWeb) {
                                    if (file.bytes == null)
                                      throw Exception(
                                        "Không có dữ liệu file Web",
                                      );
                                    return MultipartFile.fromBytes(
                                      file.bytes!,
                                      filename: file.name,
                                    );
                                  }

                                  if (file.path == null)
                                    throw Exception("Không tìm thấy file");
                                  return MultipartFile.fromFile(
                                    file.path!,
                                    filename: file.name,
                                  );
                                }),
                              );

                              try {
                                final res =
                                    await SubmissionService.createSubmission(
                                      assignmentId: assignmentId,
                                      files: filesMultipart,
                                      onProgress: (sent, total) {
                                        if (!mounted) return;
                                        setState(
                                          () => _uploadProgress = total > 0
                                              ? sent / total
                                              : 0,
                                        );
                                      },
                                    );

                                if (!mounted) return;

                                setState(() => _isUploading = false);

                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res["message"] ?? "Nộp bài thành công",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                ref.invalidate(
                                  mySubmissionProvider(assignmentId),
                                );
                              } on DioException catch (e) {
                                setState(() => _isUploading = false);

                                final msg =
                                    e.response?.data?["message"] ??
                                    "Lỗi không xác định khi nộp bài";

                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(msg),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: const Text(
                        "Nộp bài",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------
  IconData _pickIcon(String url) {
    final u = url.toLowerCase();
    if (u.endsWith(".pdf")) return Icons.picture_as_pdf;
    if (u.endsWith(".doc") || u.endsWith(".docx")) return Icons.description;
    if (u.endsWith(".zip") || u.endsWith(".rar")) return Icons.archive;
    if (u.endsWith(".ppt") || u.endsWith(".pptx")) return Icons.slideshow;
    if (u.endsWith(".xlsx") || u.endsWith(".xls"))
      return Icons.grid_view_rounded;
    return Icons.insert_drive_file;
  }

  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith(".jpg") ||
        u.endsWith(".jpeg") ||
        u.endsWith(".png") ||
        u.endsWith(".gif");
  }

  String _extractName(String url, String? fileName) {
    if (fileName != null &&
        fileName.trim().isNotEmpty &&
        fileName.trim().toLowerCase() != "file") {
      return fileName.trim();
    }

    // fallback từ url nếu fileName = null / "" / "file"
    return url.split('/').last;
  }

  String _fmt(DateTime d) {
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}";
  }
}
