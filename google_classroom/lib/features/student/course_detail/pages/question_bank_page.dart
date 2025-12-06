import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../quizz_controller.dart';

class QuestionBankPage extends ConsumerWidget {
  final int courseId;
  const QuestionBankPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionBankProvider(courseId));

    Future<void> _confirmDelete(int id) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Bạn có chắc muốn xóa câu hỏi?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Hủy", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Xóa",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(deleteQuestionProvider(id).future);
        ref.invalidate(questionBankProvider(courseId));

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xoá câu hỏi")));
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Question Bank",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có câu hỏi nào",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            itemBuilder: (_, i) {
              final q = questions[i];

              return Card(
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  title: Text(
                    q["question_text"],
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "Độ khó: ${q["difficulty"]}",
                    style: const TextStyle(color: Colors.white54),
                  ),

                  // 👉 Nhấn vào item mở chi tiết
                  onTap: () async {
                    final result = await context.push(
                      "/instructor/course/$courseId/question-detail",
                      extra: q,
                    );

                    if (result == true) {
                      // 🔥 Reload ngay UI
                      ref.invalidate(questionBankProvider(courseId));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã xoá câu hỏi")),
                      );
                    }
                  },

                  // PopupMenu chỉ xoá nhanh
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    color: Colors.grey.shade900,
                    onSelected: (value) async {
                      if (value == "delete") {
                        _confirmDelete(q["id"]);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Xóa",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          context.push("/instructor/course/$courseId/question-create");
          final created = await context.push(
            "/instructor/course/$courseId/question-create",
          );

          if (created == true && context.mounted) {
            // 🔥 Reload ngay state khi quay lại
            ref.invalidate(questionBankProvider(courseId));
          }
        },
      ),
    );
  }
}
