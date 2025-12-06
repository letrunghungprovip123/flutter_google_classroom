import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_classroom/features/student/course_detail/submission_controller.dart';

import '../assignments_controller.dart';
import '../quizz_controller.dart';
import '../material_controller.dart';

import '../../../shared/models/course_model.dart';
import '../../../../core/provider/user_controller.dart';

import './assignment_detail_page.dart';
import './quizz_detail.dart';
import './material_detail.dart';

class StudentAssignmentsPage extends ConsumerWidget {
  final CourseModel course;

  const StudentAssignmentsPage({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssign = ref.watch(courseAssignmentsProvider(course.id));
    final asyncQuizzes = ref.watch(quizzesProvider(course.id));
    final asyncMaterials = ref.watch(materialsProvider(course.id));

    final userAsync = ref.watch(userControllerProvider);
    final user = userAsync.value;
    final isInstructor = user?.role == "instructor";
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // ASSIGNMENT TITLE
            // ========================================================
            const Text(
              "Assignments",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ========================================================
            // ASSIGNMENT LIST
            // ========================================================
            asyncAssign.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Text("Error: $e", style: TextStyle(color: Colors.red)),
              ),
              data: (assignments) {
                if (assignments.isEmpty) {
                  return _emptySection("Chưa có bài tập nào");
                }

                return Column(
                  children: assignments.map((a) {
                    final deadlineText = a.deadline != null
                        ? _fmtDate(a.deadline!)
                        : "Không có ngày đến hạn";

                    final isMissing =
                        a.deadline != null &&
                        DateTime.now().isAfter(a.deadline!);

                    return GestureDetector(
                      onTap: () {
                        if (isInstructor) {
                          // 👉 Đi tới trang dành cho GIẢNG VIÊN
                          context.pushNamed(
                            'assignment_instructor_detail',
                            pathParameters: {
                              'courseId': course.id.toString(),
                              'assignmentId': a.id.toString(),
                            },
                          );
                        } else {
                          // 👉 Đi tới trang chi tiết dành cho STUDENT (giữ nguyên)
                          context.pushNamed(
                            'assignment_detail',
                            pathParameters: {
                              'courseId': course.id.toString(),
                              'assignmentId': a.id.toString(),
                            },
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment,
                              color: Colors.blue,
                              size: 38,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Ngày đến hạn: $deadlineText",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isInstructor
                                ? PopupMenuButton<String>(
                                    color: const Color(0xFF2B2B2B),
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    onSelected: (value) =>
                                        _handleAssignmentMenu(
                                          value,
                                          a.id,
                                          context,
                                          ref,
                                        ),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "Sửa",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "Xoá",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ref
                                      .watch(mySubmissionProvider(a.id))
                                      .when(
                                        loading: () => const Text(
                                          "...",
                                          style: TextStyle(
                                            color: Colors.white38,
                                          ),
                                        ),
                                        error: (_, __) => const Text(
                                          "Err",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        data: (mySub) {
                                          final attempts =
                                              mySub?.attemptNo ?? 0;
                                          final deadline = a.deadline;
                                          final now = DateTime.now();

                                          late String statusText;
                                          late Color statusColor;

                                          if (attempts == 0) {
                                            if (deadline != null &&
                                                now.isAfter(deadline)) {
                                              statusText = "Còn thiếu";
                                              statusColor = Colors.redAccent;
                                            } else {
                                              statusText = "Đã giao";
                                              statusColor = Colors.white70;
                                            }
                                          } else {
                                            statusText = "Đã nộp";
                                            statusColor = Colors.greenAccent;
                                          }

                                          return Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 14,
                                            ),
                                          );
                                        },
                                      ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 25),

            // ========================================================
            // DIVIDER
            // ========================================================
            const Divider(color: Colors.white30, thickness: 0.6),
            const SizedBox(height: 20),

            // ========================================================
            // QUIZZES TITLE
            // ========================================================
            const Text(
              "Quizzes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ========================================================
            // QUIZZES LIST
            // ========================================================
            asyncQuizzes.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Text("Error: $e", style: TextStyle(color: Colors.red)),
              ),
              data: (quizzes) {
                if (quizzes.isEmpty) {
                  return _emptySection("Chưa có quiz nào");
                }

                return Column(
                  children: quizzes.map((q) {
                    final quizId = q["id"];
                    final openTime = DateTime.parse(q["open_time"]);
                    final closeTime = DateTime.parse(q["close_time"]);
                    final instructor = q["users"]?["full_name"] ?? "Giảng viên";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz, color: Colors.blue, size: 38),
                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isInstructor) {
                                  context.pushNamed(
                                    'quiz_instructor_detail',
                                    pathParameters: {
                                      'courseId': course.id.toString(),
                                      'quizId': quizId.toString(),
                                    },
                                  );
                                } else {
                                  context.pushNamed(
                                    'quiz_detail',
                                    pathParameters: {
                                      'courseId': course.id.toString(),
                                      'quizId': quizId.toString(),
                                    },
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q["title"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Mở: ${_fmtDate(openTime)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Đóng: ${_fmtDate(closeTime)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Giảng viên: $instructor",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isInstructor)
                            PopupMenuButton<String>(
                              color: const Color(0xFF2B2B2B),
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (value) =>
                                  _handleQuizMenu(value, quizId, context, ref),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "delete",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Xoá",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          if (!isInstructor)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                              size: 28,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 10),

            if (isInstructor)
              GestureDetector(
                onTap: () {
                  context.push('/instructor/course/${course.id}/question-bank');
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.library_books,
                        color: Colors.purpleAccent,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Ngân hàng câu hỏi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 25),

            // ========================================================
            // DIVIDER
            // ========================================================
            const Divider(color: Colors.white30, thickness: 0.6),
            const SizedBox(height: 20),

            // ========================================================
            // MATERIALS TITLE
            // ========================================================
            const Text(
              "Materials",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ========================================================
            // MATERIALS LIST
            // ========================================================
            asyncMaterials.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Text("Error: $e", style: TextStyle(color: Colors.red)),
              ),
              data: (materials) {
                if (materials.isEmpty) {
                  return _emptySection("Chưa có tài liệu nào");
                }

                // --- MATERIAL LIST (thay vào vị trí hiện tại) ---
                return Column(
                  children: materials.map((m) {
                    final materialId = m["id"];
                    IconData icon = _pickMaterialIcon(m);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.book, color: Colors.blue, size: 38),
                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.pushNamed(
                                  'material_detail',
                                  pathParameters: {
                                    'courseId': course.id.toString(),
                                    'materialId': materialId.toString(),
                                  },
                                );
                              },
                              child: Text(
                                m["title"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                          if (isInstructor)
                            PopupMenuButton<String>(
                              color: const Color(0xFF2B2B2B),
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (value) => _handleMaterialMenu(
                                value,
                                materialId,
                                context,
                                ref,
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "delete",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Xoá",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          if (!isInstructor)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                              size: 28,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _openCreateMenu(context, ref),
            )
          : null,
    );
  }

  void _handleAssignmentMenu(
    String value,
    int assignmentId,
    BuildContext context,
    WidgetRef ref,
  ) async {
    // ============================
    // EDIT
    // ============================
    if (value == "edit") {
      final result = await context.push(
        "/instructor/course/${course.id}/assignment-edit/$assignmentId",
      );

      if (result == true && context.mounted) {
        ref.invalidate(courseAssignmentsProvider(course.id));
        ref.invalidate(assignmentDetailProvider(assignmentId));
      }
      return;
    }

    // ============================
    // DELETE
    // ============================
    if (value == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Xoá Assignment",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Bạn có chắc muốn xoá bài tập này không?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Huỷ", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Xoá",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await ref.read(deleteAssignmentProvider(assignmentId).future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xoá bài tập thành công"),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.invalidate(courseAssignmentsProvider(course.id));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi xoá: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleQuizMenu(
    String value,
    int quizId,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (value == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Xoá Quiz", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Bạn có chắc muốn xoá quiz này không?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Huỷ", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Xoá",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await QuizService.deleteQuiz(quizId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xoá quiz thành công"),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.invalidate(quizzesProvider(course.id));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi xoá: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleMaterialMenu(
    String value,
    int materialId,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (value == "edit") {
      final result = await context.push(
        "/instructor/course/${course.id}/material-edit/$materialId",
      );

      if (result == true && context.mounted) {
        ref.invalidate(materialsProvider(course.id));
      }
      return;
    }

    if (value == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Xoá Material",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Bạn có chắc muốn xoá tài liệu này không?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Huỷ", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Xoá",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await MaterialService.deleteMaterial(materialId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã xoá tài liệu thành công"),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.invalidate(materialsProvider(course.id));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi xoá: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------
  // ICON PICKER
  // ---------------------------------------------------------
  IconData _pickMaterialIcon(dynamic m) {
    if (m["attachments"] == null || m["attachments"].isEmpty) {
      return Icons.insert_drive_file;
    }

    final first = m["attachments"][0];
    final url = (first["file_url"] ?? "").toLowerCase();

    if (url.endsWith(".pdf")) return Icons.picture_as_pdf;
    if (url.endsWith(".ppt") || url.endsWith(".pptx")) return Icons.slideshow;
    if (url.endsWith(".doc") || url.endsWith(".docx")) return Icons.description;
    if (url.endsWith(".xls") || url.endsWith(".xlsx"))
      return Icons.grid_view_rounded;
    if (url.endsWith(".jpg") ||
        url.endsWith(".jpeg") ||
        url.endsWith(".png") ||
        url.endsWith(".gif"))
      return Icons.image;

    if (url.endsWith(".zip") || url.endsWith(".rar")) return Icons.archive;

    return Icons.insert_drive_file;
  }

  Widget _emptySection(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return "${d.year}-${d.month}-${d.day} ${d.hour}:${d.minute}";
  }

  Future<void> _openCreateMenu(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TITLE
              const Text(
                "Tạo mục mới",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ASSIGNMENT
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.blue),
                title: const Text(
                  "Tạo Assignment",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await context.push(
                    '/instructor/course/${course.id}/assignment-create',
                  );
                  if (result == true) {
                    // 🔥 BẮT BUỘC invalidate để reload UI
                    ref.invalidate(courseAssignmentsProvider(course.id));
                  }
                },
              ),

              const Divider(color: Colors.white24),

              // QUIZ
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.greenAccent),
                title: const Text(
                  "Tạo Quiz",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await context.push(
                    '/instructor/course/${course.id}/quiz-create',
                  );
                  if (result == true) {
                    ref.invalidate(quizzesProvider(course.id));
                  }
                },
              ),

              const Divider(color: Colors.white24),

              // MATERIAL
              ListTile(
                leading: const Icon(
                  Icons.menu_book,
                  color: Colors.orangeAccent,
                ),
                title: const Text(
                  "Tạo Material",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await context.push(
                    '/instructor/course/${course.id}/material-create',
                  );

                  if (result == true) {
                    ref.invalidate(materialsProvider(course.id));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
