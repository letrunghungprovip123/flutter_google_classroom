import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../submission_controller.dart';

class SubmissionListWidget extends StatefulWidget {
  final List submissions;

  const SubmissionListWidget({super.key, required this.submissions});

  @override
  State<SubmissionListWidget> createState() => _SubmissionListWidgetState();
}

class _SubmissionListWidgetState extends State<SubmissionListWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.submissions.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có ai nộp bài",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final grouped = _groupByStudent(widget.submissions);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: grouped.keys.map((stuId) {
        final attempts = grouped[stuId]!;
        final user = attempts.first["students"]["users"];
        final avatar = user["avatar_url"];
        final name = user["full_name"];

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ExpansionTile(
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            leading: CircleAvatar(
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              backgroundColor: Colors.blue,
              radius: 24,
              child: avatar == null
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              "Đã nộp ${attempts.length} lần",
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            children: attempts
                .map((sub) => _submissionItem(sub, context))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  // Group theo student_id
  Map<int, List> _groupByStudent(List list) {
    final Map<int, List> map = {};
    for (var s in list) {
      map.putIfAbsent(s["student_id"], () => []);
      map[s["student_id"]]!.add(s);
    }
    return map;
  }

  // Render mỗi submission
  Widget _submissionItem(dynamic sub, BuildContext context) {
    final submittedAt = DateTime.parse(sub["submitted_at"]);
    final status = sub["status"];
    final grade = sub["grade"];
    final statusText = status == "late" ? "Nộp trễ" : "Đúng hạn";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // attempt no
          Text(
            "Lần nộp ${sub["attempt_no"]}",
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),

          // time + status
          Text(
            "Thời gian: ${_fmt(submittedAt)}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            "Trạng thái: $statusText",
            style: TextStyle(
              color: status == "late"
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 10),

          // grade + action
          Row(
            children: [
              Text(
                "Điểm: ${grade == null ? "-" : grade.toString()}",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openGradeSheet(context, sub),
                child: Text(
                  grade == null ? "Chấm điểm" : "Sửa điểm",
                  style: const TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // attachments
          const Text("Tệp đính kèm:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),

          ...sub["attachments"].map<Widget>((file) {
            final url = file["file_url"];
            final name = file["file_name"]?.trim().isNotEmpty == true
                ? file["file_name"]
                : _extractName(url);

            return GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _pickIcon(url),
                      color: Colors.lightBlueAccent,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white30),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // BottomSheet nhập điểm
  void _openGradeSheet(BuildContext context, dynamic sub) {
    final controller = TextEditingController(
      text: sub["grade"]?.toString() ?? "",
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nhập điểm",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "0 - 10",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 50,
                  ),
                ),
                onPressed: () async {
                  final val = double.tryParse(controller.text);

                  if (val == null || val < 0 || val > 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Điểm không hợp lệ! (Chỉ từ 0 → 10)"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  await SubmissionService.updateGrade(
                    submissionId: sub["id"],
                    grade: val,
                  );

                  sub["grade"] = val; // update local UI

                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cập nhật điểm thành công!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  "Lưu điểm",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Utils
  String _fmt(DateTime d) =>
      "${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  String _extractName(String url) => url.split('/').last;

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
}
