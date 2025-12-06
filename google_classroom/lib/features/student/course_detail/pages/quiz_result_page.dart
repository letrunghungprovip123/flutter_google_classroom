import 'package:flutter/material.dart';

class QuizResultPage extends StatelessWidget {
  final double score;
  final int correct;
  final int total;
  final Map<String, dynamic> attemptData;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.correct,
    required this.total,
    required this.attemptData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Kết quả quiz",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CARD SCORE
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Điểm của bạn",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$score",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$correct / $total câu đúng",
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // MORE INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin bài làm",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Thời gian nộp: ${attemptData["submitted_at"] ?? "N/A"}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    "Attempt ID: ${attemptData["id"]}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // BACK BUTTON
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Quay về quiz",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
