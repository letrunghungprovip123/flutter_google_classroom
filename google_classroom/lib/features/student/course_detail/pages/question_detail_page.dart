import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../quizz_controller.dart';

class QuestionDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;

  const QuestionDetailPage({super.key, required this.question});

  @override
  ConsumerState<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends ConsumerState<QuestionDetailPage> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final correct = (q["correct_option"] ?? "").toUpperCase();

    Widget buildOption(String label, String? text) {
      final isCorrect = label == correct;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCorrect
              ? Colors.green.withOpacity(0.15)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCorrect ? Colors.greenAccent : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCorrect ? Colors.green : Colors.white24,
              child: Text(
                label,
                style: TextStyle(
                  color: isCorrect ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text ?? "--",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle, color: Colors.greenAccent),
          ],
        ),
      );
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
          "Chi tiết câu hỏi",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.grey.shade900,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == "delete") {
                _confirmDelete(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text("Xóa", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q["question_text"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Difficulty: ${q["difficulty"].toUpperCase()}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  buildOption("A", q["option_a"]),
                  buildOption("B", q["option_b"]),
                  buildOption("C", q["option_c"]),
                  buildOption("D", q["option_d"]),
                ],
              ),
            ),
          ),

          if (isDeleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final qId = widget.question["id"];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Bạn có chắc muốn xóa câu hỏi này?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeleting = true);

    try {
      await ref.read(deleteQuestionProvider(qId).future);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Xóa thành công!")));

      Navigator.pop(context, true); // ⬅ Trả về để reload list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Xóa thất bại: $e")));
    } finally {
      if (mounted) setState(() => isDeleting = false);
    }
  }
}
