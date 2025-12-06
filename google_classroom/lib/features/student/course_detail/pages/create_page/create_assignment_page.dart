import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_client.dart';
import '../../assignments_controller.dart';

class CreateAssignmentPage extends ConsumerStatefulWidget {
  final int courseId;
  final int? assignmentId;

  const CreateAssignmentPage({
    super.key,
    required this.courseId,
    this.assignmentId,
  });

  @override
  ConsumerState<CreateAssignmentPage> createState() =>
      _CreateAssignmentPageState();
}

// Để hiển thị file cũ từ server
class _ExistingAttachment {
  final int id;
  final String name;
  final String url;

  _ExistingAttachment({
    required this.id,
    required this.name,
    required this.url,
  });
}

class _CreateAssignmentPageState extends ConsumerState<CreateAssignmentPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxAttemptCtrl = TextEditingController(text: "1");

  DateTime? startDate;
  DateTime? deadline;
  DateTime? lateDeadline;

  bool allowLate = false;
  bool isSubmitting = false;
  bool isEdit = false;

  // File mới chọn ở FE
  List<PlatformFile> selectedFiles = [];

  // File đã tồn tại trên server (attachments)
  List<_ExistingAttachment> existingFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.assignmentId != null) {
      isEdit = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final data = await ref.read(
      assignmentDetailProvider(widget.assignmentId!).future,
    );

    _titleCtrl.text = data.title;
    _descCtrl.text = data.description ?? "";
    _maxAttemptCtrl.text = data.maxAttempts?.toString() ?? "1";
    startDate = data.startDate;
    deadline = data.deadline;
    lateDeadline = data.lateDeadline;
    allowLate = data.allowLate ?? false;

    // Map attachments từ API sang list hiển thị
    // Giả sử data.attachments có: id, fileName, fileUrl
    if (data.attachments != null) {
      existingFiles = data.attachments!
          .map<_ExistingAttachment>(
            (a) => _ExistingAttachment(
              id: a.id,
              name: a.fileName ?? 'Tài liệu',
              url: a.fileUrl ?? '',
            ),
          )
          .toList();
    }

    setState(() {});
  }

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() => selectedFiles.addAll(result.files));
      }
    } catch (e) {
      _showError("Không mở được chọn file: $e");
    }
  }

  void removeFile(int index) => setState(() => selectedFiles.removeAt(index));

Future<MultipartFile> _toMultipart(PlatformFile file) async {
    // Giới hạn dung lượng file (ví dụ: 20MB = 20 * 1024 * 1024)
    const maxFileSize = 20 * 1024 * 1024;

    if ((file.size) > maxFileSize) {
      throw Exception(
        "File quá lớn (${(file.size / 1024 / 1024).toStringAsFixed(1)}MB). Tối đa 20MB",
      );
    }

    // WEB xử lý bằng bytes
    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception("File dữ liệu bị null trên Web");
      }

      return MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: null, // 🔥 Browser tự detect → an toàn nhất
      );
    }

    // MOBILE / DESKTOP xử lý bằng path
    if (file.path == null) throw Exception("Không tìm thấy file path");

    final fileObj = File(file.path!);
    final fileSize = await fileObj.length();

    if (fileSize > maxFileSize) {
      throw Exception(
        "File quá lớn (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Tối đa 20MB",
      );
    }

    return MultipartFile.fromFile(
      file.path!,
      filename: file.name,
      contentType: null, // 🔥 Để OS/Dio tự detect
    );
  }

  Future<void> submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      return _showError("Vui lòng nhập tiêu đề");
    }
    if (deadline == null) {
      return _showError("Vui lòng chọn deadline");
    }

    final maxA = int.tryParse(_maxAttemptCtrl.text.trim());
    if (maxA == null || maxA <= 0) {
      return _showError("Số lần allowed không hợp lệ");
    }

    setState(() => isSubmitting = true);

    final files = await Future.wait(selectedFiles.map(_toMultipart));

    final payload = {
      "id": isEdit ? widget.assignmentId : null,
      "course_id": widget.courseId,
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "start_date": startDate?.toIso8601String(),
      "deadline": deadline?.toIso8601String(),
      "late_deadline": allowLate ? lateDeadline?.toIso8601String() : null,
      "allow_late": allowLate,
      "max_attempts": maxA,
      "files": files,
      // hiện tại chỉ hiển thị file cũ, chưa gửi logic xóa/giữ lên backend
    };

    try {
      if (isEdit) {
        await ref.read(updateAssignmentProvider(payload).future);
      } else {
        await ref.read(createAssignmentProvider(payload).future);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Cập nhật thành công!" : "Tạo bài tập thành công!",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print(e);
      debugPrint(e.toString());
      _showError("Thao tác thất bại");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> pickDate(void Function(DateTime) onSelect) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date != null) {
      onSelect(date);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.grey.shade900,
        title: Text(
          isEdit ? "Chỉnh sửa Assignment" : "Tạo Assignment",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEdit ? "Lưu thay đổi" : "Tạo bài tập",
                    style: const TextStyle(fontSize: 17),
                  ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input("Tiêu đề *", _titleCtrl),
          const SizedBox(height: 12),
          _input("Mô tả", _descCtrl, maxLines: 3),
          const SizedBox(height: 16),
          _dateTile(
            "Start date",
            startDate,
            () => pickDate((d) => startDate = d),
          ),
          const SizedBox(height: 10),
          _dateTile(
            "Deadline *",
            deadline,
            () => pickDate((d) => deadline = d),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cho phép nộp trễ",
                style: TextStyle(color: Colors.white),
              ),
              Switch(
                value: allowLate,
                activeColor: Colors.blueAccent,
                onChanged: (v) => setState(() => allowLate = v),
              ),
            ],
          ),
          if (allowLate)
            _dateTile(
              "Late deadline",
              lateDeadline,
              () => pickDate((d) => lateDeadline = d),
            ),
          const SizedBox(height: 16),
          _input(
            "Số lần allowed",
            _maxAttemptCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ====== FILE CŨ TỪ SERVER (EDIT MODE) ======
          if (isEdit && existingFiles.isNotEmpty) ...[
            const Text(
              "Tài liệu hiện có",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...existingFiles.map(
              (f) => Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.white60),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    // Hiện tại chỉ hiển thị, không xóa backend
                    // Nếu sau này muốn xóa, sẽ thêm nút ở đây
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ====== CHỌN FILE MỚI ======
          ElevatedButton.icon(
            onPressed: pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text("Thêm tài liệu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 12),

          // File mới chọn
          ...selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.white60),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => removeFile(index),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null ? value.toString().substring(0, 16) : label,
                style: TextStyle(
                  color: value == null ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
