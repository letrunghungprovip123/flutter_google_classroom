import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import './student_dashboard_controller.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  String fmt(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDash = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: asyncDash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            "Lỗi tải dashboard: $err",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (d) {
          final user = d["user"];
          final ov = d["overview"];

          final submitted = ov["totalSubmittedAssignments"];
          final pending = ov["totalPendingAssignments"];
          final late = ov["totalLateAssignments"];
          final quizzes = ov["totalCompletedQuizzes"];

          final submittedList = d["submittedAssignments"];
          final completedQuizzes = d["completedQuizzes"];
          final upcoming = d["upcomingDeadlines"];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(user, submitted, pending, late, quizzes),
              const SizedBox(height: 24),

              _barChart(submitted, pending, late, quizzes),
              const SizedBox(height: 30),

              if (completedQuizzes.isNotEmpty)
                _quizScoreChart(completedQuizzes),
              const SizedBox(height: 30),

              _completedQuizzes(context, completedQuizzes),
              const SizedBox(height: 30),

              _upcoming(context, upcoming),
              const SizedBox(height: 30),

              _recent(context, submittedList),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  // ====================== HEADER ======================
  Widget _header(user, submitted, pending, late, quizzes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user["avatar_url"] != null
                  ? NetworkImage(user["avatar_url"])
                  : null,
              child: user["avatar_url"] == null
                  ? Text(
                      user["full_name"][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Welcome back!",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        _overviewRow(submitted, pending, late, quizzes),
      ],
    );
  }

  Widget _overviewBox(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _overviewRow(sub, pen, late, quiz) {
    return Row(
      children: [
        _overviewBox("Submitted", sub, Colors.greenAccent),
        const SizedBox(width: 10),
        _overviewBox("Pending", pen, Colors.orangeAccent),
        const SizedBox(width: 10),
        _overviewBox("Late", late, Colors.redAccent),
        const SizedBox(width: 10),
        _overviewBox("Quizzes", quiz, Colors.lightBlueAccent),
      ],
    );
  }

  // ====================== BAR CHART ======================
  Widget _barChart(sub, pen, late, quiz) {
    final data = [
      sub.toDouble(),
      pen.toDouble(),
      late.toDouble(),
      quiz.toDouble(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Learning Progress",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (data.reduce((a, b) => a > b ? a : b) + 2),
                barTouchData: BarTouchData(enabled: true),

                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (i, _) {
                        const labels = ["Sub", "Pend", "Late", "Quiz"];
                        return Text(
                          labels[i.toInt()],
                          style: const TextStyle(color: Colors.white70),
                        );
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                barGroups: [
                  _barItem(0, sub.toDouble(), Colors.greenAccent),
                  _barItem(1, pen.toDouble(), Colors.orangeAccent),
                  _barItem(2, late.toDouble(), Colors.redAccent),
                  _barItem(3, quiz.toDouble(), Colors.lightBlueAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barItem(int x, double y, Color c) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: c,
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // ====================== LINE CHART (quiz scores) ======================
  Widget _quizScoreChart(List quizzes) {
    final points = <FlSpot>[];

    for (int i = 0; i < quizzes.length; i++) {
      final score = double.tryParse(quizzes[i]["score"] ?? "0") ?? 0;
      points.add(FlSpot(i.toDouble(), score));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Quiz Score Trend",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                borderData: FlBorderData(show: false),

                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],

                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (x, _) => Text(
                        "Q${x.toInt() + 1}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== COMPLETED QUIZZES LIST ======================
  Widget _completedQuizzes(BuildContext context, List quizzes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Completed Quizzes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...quizzes.map((q) {
          final score = double.tryParse(q["score"] ?? "0") ?? 0.0;

          return GestureDetector(
            onTap: () {
              context.push(
                "/student/course/${q["courseId"]}/quiz/${q["quizId"]}",
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: score >= 5 ? Colors.green : Colors.redAccent,
                    ),
                    child: Center(
                      child: Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q["submittedAt"] == null
                              ? "Not submitted"
                              : "Submitted: ${fmt(q["submittedAt"])}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ====================== UPCOMING DEADLINES ======================
  Widget _upcoming(BuildContext context, List list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Deadlines",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...list.map((item) {
          final isQuiz = item["type"] == "quiz";

          return GestureDetector(
            onTap: () {
              if (isQuiz) {
                context.push(
                  "/student/course/${item["courseId"]}/quiz/${item["id"]}",
                );
              } else {
                context.push(
                  "/student/course/${item["courseId"]}/assignment/${item["id"]}",
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isQuiz ? Icons.quiz : Icons.assignment,
                    color: Colors.lightBlueAccent,
                    size: 30,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isQuiz
                              ? "Close: ${fmt(item["closeTime"])}"
                              : "Deadline: ${fmt(item["deadline"])}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ====================== RECENT SUBMISSIONS ======================
  Widget _recent(BuildContext context, List list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Submissions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...list.map((item) {
          final color = item["status"] == "on_time"
              ? Colors.greenAccent
              : Colors.redAccent;

          return GestureDetector(
            onTap: () {
              context.push(
                "/student/course/${item["courseId"]}/assignment/${item["assignmentId"]}",
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Submitted: ${fmt(item["submittedAt"])}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
