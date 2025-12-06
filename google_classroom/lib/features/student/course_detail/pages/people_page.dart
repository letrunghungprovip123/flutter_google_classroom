import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_classroom/core/provider/user_controller.dart';
import 'package:google_classroom/features/student/course_detail/message_controller.dart';
import 'package:google_classroom/features/student/course_detail/pages/import_group_student_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/message_page.dart';
import '../course_detail_controller.dart';
import '../../../shared/models/course_model.dart';

class StudentPeoplePage extends ConsumerWidget {
  final CourseModel course;

  const StudentPeoplePage({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userControllerProvider);
    final asyncGroups = ref.watch(groupsProvider(course.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text(
            "User load error: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (user) {
          final bool isInstructor = user?.role == "instructor";

          return asyncGroups.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (err, _) =>
                Text("$err", style: const TextStyle(color: Colors.redAccent)),
            data: (groups) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section("Giáo viên"),
                _teacher(course.teacher),

                const SizedBox(height: 25),
                _section("Nhóm"),

                const SizedBox(height: 15),
                ...groups.map((g) => _groupCard(context, ref, g, isInstructor)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

Widget _teacher(String teacherName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal,
          child: Text(
            teacherName.isNotEmpty ? teacherName[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teacherName,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),

        Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(userControllerProvider).value;
            final isInstructor = user?.role == "instructor";

            if (isInstructor) return const SizedBox();

            return IconButton(
              tooltip: "Nhắn tin với giáo viên",
              icon: const Icon(Icons.chat, color: Colors.lightBlueAccent),
              onPressed: () async {
                try {
                  final res = await ref.read(createConversationProvider({}).future);
                  final data = res["data"];

                  if (data == null || data["id"] == null) {
                    throw Exception("Không lấy được conversationId");
                  }

                  final conversationId = data["id"];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessagePage(
                        conversationId: conversationId,
                        title: teacherName,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi mở cuộc trò chuyện: $e")),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }


  Widget _groupCard(
    BuildContext context,
    WidgetRef ref,
    Map g,
    bool isInstructor,
  ) {
    final List students = g["students"] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                g["name"],
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              if (isInstructor) ...[
                IconButton(
                  tooltip: "Thêm sinh viên vào nhóm",
                  icon: const Icon(Icons.person_add, color: Colors.greenAccent),
                  onPressed: () => _addStudentDialog(context, ref, g["id"]),
                ),
                IconButton(
                  tooltip: "Import CSV",
                  icon: const Icon(
                    Icons.upload_file,
                    color: Colors.lightBlueAccent,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImportGroupStudentsPage(
                          courseId: course.id,
                          groupId: g["id"],
                        ),
                      ),
                    ).then((_) {
                      ref.refresh(groupsProvider(course.id));
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          if (students.isEmpty)
            const Text(
              "Chưa có sinh viên",
              style: TextStyle(color: Colors.white70),
            ),

          ...students.map(
            (s) => _studentItem(context, ref, g["id"], s, isInstructor),
          ),
        ],
      ),
    );
  }

Widget _studentItem(
    BuildContext context,
    WidgetRef ref,
    int groupId,
    Map s,
    bool isInstructor,
  ) {
    final user = s["user"];
    final name = user["full_name"];
    final email = user["email"];
    final avatarUrl = user["avatar_url"];
    final studentUserId = user["id"]; // Lấy user_id để chat

    final loggedInUser = ref.read(userControllerProvider).value;
    final isSelf = loggedInUser?.id == studentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: avatarUrl == null ? Colors.blueGrey : null,
            child: avatarUrl == null
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          if (isInstructor)
            Row(
              children: [
                /// ========== 🟦 CHAT BUTTON ==========
                if (!isSelf) // không cho nhắn chính mình
                  IconButton(
                    tooltip: "Nhắn tin với sinh viên",
                    icon: const Icon(Icons.chat, color: Colors.lightBlueAccent),
                    onPressed: () async {
                      try {
                        /// Gửi studentUserId lên BE ⭐
                        final res = await ref.read(
                          createConversationProvider({
                            "studentUserId": studentUserId,
                          }).future,
                        );

                        final data = res["data"];
                        final conversationId = data["id"];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagePage(
                              conversationId: conversationId,
                              title: name,
                            ),
                          ),
                        );
                      } catch (err) {
                        String message = "Lỗi mở cuộc trò chuyện";
                        if (err is DioException) {
                          message =
                              err.response?.data["message"] ??
                              err.message ??
                              message;
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                  ),

                /// ========== 🟥 REMOVE BUTTON ==========
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () =>
                      _removeStudent(context, ref, groupId, s["student_id"]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ===== ADD STUDENT =====
  void _addStudentDialog(BuildContext context, WidgetRef ref, int groupId) {
    final input = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Thêm sinh viên",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: input,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Mã sinh viên",
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Huỷ"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Thêm"),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref.read(
                  addStudentToGroupProvider({
                    "courseId": course.id,
                    "groupId": groupId,
                    "student_code": input.text.trim(),
                  }).future,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thêm thành công")),
                );
              } catch (err) {
                String message = "Lỗi không xác định";

                if (err is DioException) {
                  message =
                      err.response?.data["message"] ?? err.message ?? message;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
          ),
        ],
      ),
    );
  }

  // ===== REMOVE STUDENT =====
  void _removeStudent(
    BuildContext context,
    WidgetRef ref,
    int groupId,
    int studentId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Xoá sinh viên",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bạn có chắc chắn không?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Huỷ"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xoá"),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref.read(
                  removeStudentFromGroupProvider({
                    "courseId": course.id,
                    "groupId": groupId,
                    "studentId": studentId,
                  }).future,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Đã xoá")));
              } catch (err) {
                String message = "Lỗi không xác định";

                if (err is DioException) {
                  message =
                      err.response?.data["message"] ?? err.message ?? message;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
          ),
        ],
      ),
    );
  }
}
