import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../quizz_controller.dart';

class QuizInstructorDetailPage extends ConsumerStatefulWidget {
  final int quizId;
  const QuizInstructorDetailPage({super.key, required this.quizId});

  @override
  ConsumerState<QuizInstructorDetailPage> createState() =>
      _QuizInstructorDetailPageState();
}

class _QuizInstructorDetailPageState
    extends ConsumerState<QuizInstructorDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuiz = ref.watch(quizDetailProvider(widget.quizId));

    return asyncQuiz.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Lỗi: $e", style: TextStyle(color: Colors.red)),
        ),
      ),
      data: (quiz) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Quản lý Quiz",
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tab,
            labelColor: Colors.lightBlueAccent,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.lightBlueAccent,
            tabs: const [
              Tab(text: "Thông tin"),
              Tab(text: "Bài làm"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [_infoTab(quiz), _attemptsTab(quiz)],
        ),
      ),
    );
  }

  // TAB 1
  Widget _infoTab(dynamic q) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          q["title"],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        _item("Thời gian mở:", _fmt(q["open_time"])),
        _item("Thời hạn:", _fmt(q["close_time"])),
        _item("Thời lượng:", "${q["duration_minutes"]} phút"),
        _item("Số lần làm tối đa:", "${q["max_attempts"]} lần"),
        _item("Random dễ:", "${q["random_easy"]} câu"),
        _item("Random trung bình:", "${q["random_medium"]} câu"),
        _item("Random khó:", "${q["random_hard"]} câu"),
      ],
    );
  }

  Widget _item(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    ),
  );

  // TAB 2
  Widget _attemptsTab(dynamic q) {
    final attempts = q["quiz_attempts"] as List;
    final total = q["stats"]["totalStudentsAttempted"];

    if (attempts.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có ai làm bài",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          "Đã có $total sinh viên làm quiz",
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),

        ...attempts.map((a) {
          final user = a["students"]["users"];
          final score = a["score"] == null ? "0" : a["score"].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  backgroundImage: user["avatar_url"] != null
                      ? NetworkImage(user["avatar_url"])
                      : null,
                  child: user["avatar_url"] == null
                      ? Text(
                          user["full_name"][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    user["full_name"],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                Row(
                  children: [
                    Text(
                      "Score :",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),

                    const SizedBox(width: 10),
                    Text(
                      score,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: a["score"] == null
                            ? Colors.white38
                            : Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _fmt(String iso) {
    final d = DateTime.parse(iso);
    return "${d.day}/${d.month}/${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }
}
