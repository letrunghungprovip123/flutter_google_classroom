import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/provider/user_controller.dart';
import '../../../shared/models/course_model.dart';
import '../announcement_controller.dart';
import '../comment_controller.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class StudentStreamPage extends ConsumerStatefulWidget {
  final CourseModel course;
  final List<dynamic> announcements; // cache ban đầu từ CourseDetail

  const StudentStreamPage({
    super.key,
    required this.course,
    required this.announcements,
  });

  @override
  ConsumerState<StudentStreamPage> createState() => _StudentStreamPageState();
}

class _StudentStreamPageState extends ConsumerState<StudentStreamPage> {
  List<dynamic> announcementList = [];

  @override
  void initState() {
    super.initState();

    // 1️⃣ Dùng cache ban đầu để UI không trắng
    announcementList = List.from(widget.announcements);

    // 2️⃣ Fetch lại từ API qua provider, update announcementList
    Future.microtask(() async {
      final state = ref.read(announcementProvider(widget.course.id));
      state.whenData((data) {
        // data này đã có "users"
        // debug:
        // print("🎯 Announcement from provider: $data");
        if (mounted) setState(() => announcementList = data);
      });
    });
  }

  void removeAnn(int id) {
    setState(() {
      announcementList.removeWhere((e) => e["id"] == id);
    });
  }

  String formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return "Hôm nay";
    if (diff.inDays == 1) return "Hôm qua";
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  // ====================================================
  // MODAL CREATE NEW ANNOUNCEMENT
  // ====================================================
  void _openCreateAnnouncementModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    List<PlatformFile> selectedFiles = [];
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
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
                    "Tạo thông báo mới",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TITLE
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Tiêu đề",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CONTENT
                  TextField(
                    controller: contentCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Nội dung",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FILE PICKER
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
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
                        "Đính kèm tập tin",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Show selected files
                  ...selectedFiles.map(
                    (f) => Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.name,
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: isPosting
                          ? null
                          : () async {
                              final user = ref
                                  .read(userControllerProvider)
                                  .value;
                              if (user == null) return;

                              modalSet(() => isPosting = true);

                              final files = await Future.wait(
                                selectedFiles.map((f) async {
                                  // Max 20MB
                                  const maxSize = 20 * 1024 * 1024;
                                  if (f.size > maxSize) {
                                    throw Exception("File quá lớn: >20MB");
                                  }

                                  if (kIsWeb) {
                                    if (f.bytes == null) {
                                      throw Exception(
                                        "File bytes null trên Web",
                                      );
                                    }
                                    return MultipartFile.fromBytes(
                                      f.bytes!,
                                      filename: f.name,
                                      contentType: null,
                                    );
                                  }

                                  if (f.path == null) {
                                    throw Exception(
                                      "Không tìm thấy file path (Desktop/Mobile)",
                                    );
                                  }

                                  return MultipartFile.fromFile(
                                    f.path!,
                                    filename: f.name,
                                    contentType: null,
                                  );
                                }),
                              );

                              await ref
                                  .read(
                                    announcementProvider(
                                      widget.course.id,
                                    ).notifier,
                                  )
                                  .createAnnouncement(
                                    title: titleCtrl.text.trim(),
                                    content: contentCtrl.text.trim(),
                                    files: files,
                                  );

                              // Sau khi tạo xong, đọc lại provider để cập nhật list
                              final state = ref.read(
                                announcementProvider(widget.course.id),
                              );

                              state.whenData((list) {
                                if (mounted) {
                                  setState(() => announcementList = list);
                                }
                              });

                              modalSet(() => isPosting = false);

                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            },
                      child: isPosting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.3,
                              ),
                            )
                          : const Text(
                              "Đăng thông báo",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ====================================================
  // MAIN UI
  // ====================================================
  @override
  Widget build(BuildContext context) {
    // Không dùng annState để render nữa, chỉ dùng nó để load ở init/modal
    final list = announcementList;

    final userAsync = ref.watch(userControllerProvider);
    final user = userAsync.value;
    final isInstructor = user?.role == "instructor"; // 👈 thêm

    final announcementsUI = list.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Chưa có thông báo nào.",
              style: TextStyle(color: Colors.white70),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list
                .map(
                  (a) => _AnnouncementCard(
                    teacher: a["users"]?["full_name"] ?? "Không rõ",
                    avatarUrl: a["users"]?["avatar_url"],
                    content: a["content"],
                    createdAt: a["created_at"],
                    attachments: a["attachments"] ?? [],
                    timeFormat: formatTime,
                    ref: ref,
                    courseId: widget.course.id,
                    annId: a["id"],
                    removeOnDelete: removeAnn,
                    isInstructor: isInstructor,
                  ),
                )
                .toList(),
          );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.course.background),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomLeft,
              child: Text(
                widget.course.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // CREATE BUTTON
          InkWell(
            onTap: _openCreateAnnouncementModal,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 92, 138, 185),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Thông báo mới",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ANNOUNCEMENTS LIST
          announcementsUI,
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// CARD HIỂN THỊ THÔNG BÁO
////////////////////////////////////////////////////////

class _AnnouncementCard extends StatelessWidget {
  final String teacher;
  final String? avatarUrl;
  final String content;
  final String createdAt;
  final List<dynamic> attachments;
  final String Function(DateTime) timeFormat;
  final WidgetRef ref;
  final int courseId;
  final int annId;
  final removeOnDelete;
  final bool isInstructor;

  const _AnnouncementCard({
    required this.teacher,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
    required this.attachments,
    required this.timeFormat,
    required this.ref,
    required this.courseId,
    required this.annId,
    required this.removeOnDelete,
    required this.isInstructor,
  });

  // ICON THEO FILE TYPE
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

    if (u.endsWith(".json") ||
        u.endsWith(".js") ||
        u.endsWith(".html") ||
        u.endsWith(".css")) {
      return Icons.code;
    }

    return Icons.insert_drive_file;
  }

  // Build UI của file đính kèm
  Widget _buildAttachment(dynamic file, BuildContext context) {
    final url = file["file_url"] ?? file["url"] ?? "";
    final name = file["file_name"];

    return GestureDetector(
      onTap: () async => launchExternal(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_pickFileIcon(url), color: Colors.blueAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(createdAt);

    // ===================== COMMENT COUNT =====================
    final commentState = ref.watch(commentsProvider(annId));

    Widget commentCountWidget = commentState.when(
      data: (comments) {
        final count = comments.length;
        final label = count == 0
            ? "Thêm nhận xét trong lớp học"
            : "$count nhận xét trong lớp học";

        return GestureDetector(
          onTap: () {
            context.push(
              '/student/course/$courseId/announcement/$annId/comments',
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          "Đang tải nhận xét...",
          style: TextStyle(color: Colors.white54),
        ),
      ),
      error: (err, _) => const SizedBox(height: 0),
    );

    // ===================== CARD UI =====================
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================== HEADER =====================
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        teacher.isNotEmpty ? teacher[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // NAME + TIME
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timeFormat(dt),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),

              const Spacer(),

              // DELETE MENU
              if (isInstructor)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.white,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final ok = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Xoá thông báo"),
                          content: const Text(
                            "Bạn có chắc muốn xoá thông báo này không?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Huỷ"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Xoá"),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await ref
                            .read(announcementProvider(courseId).notifier)
                            .deleteAnnouncement(annId);

                        removeOnDelete(annId);

                        ref.invalidate(announcementProvider(courseId));
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Xoá thông báo"),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ===================== CONTENT =====================
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),

          const SizedBox(height: 16),

          // ===================== ATTACHMENTS =====================
          if (attachments.isNotEmpty)
            ...attachments.map((file) => _buildAttachment(file, context)),

          const SizedBox(height: 5),

          Divider(color: Colors.white24, thickness: 0.5),

          // ===================== COMMENT COUNT =====================
          commentCountWidget,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// OPEN EXTERNAL URL
// -----------------------------------------------------------
Future<void> launchExternal(String url) async {
  final uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception("Không mở được file: $url");
  }
}
