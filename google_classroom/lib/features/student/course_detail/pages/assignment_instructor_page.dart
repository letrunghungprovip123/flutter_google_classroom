import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../submission_controller.dart';
import '../../../shared/models/submission_model.dart';
import '../../../shared/models/assignment_model.dart';
import 'widget/submission_list_widget.dart';
import 'package:google_classroom/features/student/course_detail/assignments_controller.dart';

class AssignmentInstructorDetailPage extends ConsumerStatefulWidget {
  final int assignmentId;
  const AssignmentInstructorDetailPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentInstructorDetailPage> createState() =>
      _AssignmentInstructorDetailPageState();
}

class _AssignmentInstructorDetailPageState
    extends ConsumerState<AssignmentInstructorDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssignment = ref.watch(
      assignmentDetailProvider(widget.assignmentId),
    );

    return asyncAssignment.when(
      loading: _loading,
      error: _error,
      data: (assignment) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "Quản lý Assignment",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.lightBlueAccent,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.lightBlueAccent,
            tabs: const [
              Tab(text: "Hướng dẫn"),
              Tab(text: "Bài nộp"),
            ],
          ),
        ),

        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _tabInstruction(assignment),
            _tabSubmissions(assignment.id),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 1: INSTRUCTOR VIEW ASSIGNMENT DETAILS
  // ---------------------------------------------------------
  Widget _tabInstruction(AssignmentModel a) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          a.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (a.description != null)
          Text(
            a.description!,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        const SizedBox(height: 20),
        _buildDeadline(a),
        const SizedBox(height: 20),
        _buildAttachments(a),
      ],
    );
  }

  // ---------------------------------------------------------
  // TAB 2: LIST OF STUDENT SUBMISSIONS
  // ---------------------------------------------------------
  Widget _tabSubmissions(int assignmentId) {
    final asyncSubs = ref.watch(submissionsProvider(assignmentId));

    return asyncSubs.when(
      loading: _loading,
      error: _error,
      data: (subs) => SubmissionListWidget(submissions: subs),
    );
  }

  // ---------------------------------------------------------
  // DEADLINE UI
  // ---------------------------------------------------------
  Widget _buildDeadline(AssignmentModel a) {
    final deadline = a.deadline;
    final now = DateTime.now();
    final isLate = deadline != null && now.isAfter(deadline);

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
              deadline == null
                  ? "Không có hạn nộp"
                  : "${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour}:${deadline.minute}",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Text(
            isLate ? "Đã hết hạn" : "Đang mở",
            style: TextStyle(
              color: isLate ? Colors.redAccent : Colors.greenAccent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // ATTACHMENT LIST UI
  // ---------------------------------------------------------
  Widget _buildAttachments(AssignmentModel a) {
    if (a.attachments.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tệp đính kèm",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),

        ...a.attachments.map((file) {
          final url = file.fileUrl;
          final name = file.fileName ?? _extractName(url);

          return GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_pickIcon(url), color: Colors.lightBlueAccent, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // ---------------------------------------------------------
  // COMMON
  // ---------------------------------------------------------
  Widget _loading() =>
      const Center(child: CircularProgressIndicator(color: Colors.white));

  Widget _error(Object e, _) => Center(
    child: Text("Lỗi: $e", style: const TextStyle(color: Colors.red)),
  );

  IconData _pickIcon(String url) {
    final u = url.toLowerCase();

    if (u.endsWith(".pdf")) return Icons.picture_as_pdf;
    if (u.endsWith(".doc") || u.endsWith(".docx")) return Icons.description;
    if (u.endsWith(".ppt") || u.endsWith(".pptx")) return Icons.slideshow;
    if (u.endsWith(".xls") || u.endsWith(".xlsx"))
      return Icons.grid_view_rounded;
    if (u.endsWith(".jpg") ||
        u.endsWith(".jpeg") ||
        u.endsWith(".png") ||
        u.endsWith(".gif"))
      return Icons.image;
    if (u.endsWith(".zip") || u.endsWith(".rar")) return Icons.archive;

    return Icons.insert_drive_file;
  }

  String _extractName(String url) => url.split('/').last;
}
