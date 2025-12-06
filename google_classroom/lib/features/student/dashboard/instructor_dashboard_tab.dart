import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_classroom/features/student/home/student_home_state.dart';
import './mock_dashboard_data.dart';
import '../dashboard/student_dashboard_controller.dart';

class InstructorDashboardTab extends ConsumerStatefulWidget {
  const InstructorDashboardTab({super.key});

  @override
  ConsumerState<InstructorDashboardTab> createState() =>
      _InstructorDashboardTabState();
}

class _InstructorDashboardTabState
    extends ConsumerState<InstructorDashboardTab> {
  int? _selectedCourseId;
  int? _selectedGroupId;
  String? _selectedStatus;
  String? _searchText;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final semesterId = ref.read(selectedSemesterIdProvider);
    if (semesterId == null) return;
    final filter = DashboardFilter(
      semesterId: semesterId,
      courseId: _selectedCourseId,
      groupId: _selectedGroupId,
      status: _selectedStatus,
      search: _searchText,
    );

    final progressAsync = ref.watch(
      instructorDashboardProgressProvider(filter),
    );


    ref.invalidate(instructorDashboardOverviewProvider(semesterId));
    ref.invalidate(instructorDashboardProgressProvider(filter));
  }

  Future<void> _exportCsv(BuildContext context, String type) async {
    try {
      final semesterId = ref.read(selectedSemesterIdProvider);
      if (semesterId == null) return;

      final result = await ref.read(
        exportCSVProvider({"semesterId": semesterId, "type": type}).future,
      );

      final rows = result.rows;
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No data to export for this type.")),
          );
        }
        return;
      }

      // Convert List<Map<String, dynamic>> -> List<List<dynamic>>
      final headers = rows.first.keys.toList();
      final dataRows = rows
          .map((row) => headers.map((h) => row[h]).toList())
          .toList();

      final csvData = const ListToCsvConverter().convert([
        headers,
        ...dataRows,
      ]);

      final bytes = Uint8List.fromList(utf8.encode(csvData));

      await FileSaver.instance.saveFile(
        name: result.filename,
        bytes: bytes,
        fileExtension: "csv",
        mimeType: MimeType.csv,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Exported: ${result.filename}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semesterId = ref.watch(selectedSemesterIdProvider);

    if (semesterId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Please select a semester",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final overviewAsync = ref.watch(
      instructorDashboardOverviewProvider(semesterId),
    );


    final progressFilters = {
      "semesterId": semesterId,
      "courseId": _selectedCourseId,
      "groupId": _selectedGroupId,
      "status": _selectedStatus,
      "search": _searchText,
    };
    final filter = DashboardFilter(
      semesterId: semesterId,
      courseId: _selectedCourseId,
      groupId: _selectedGroupId,
      status: _selectedStatus,
      search: _searchText,
    );


    final progressAsync = ref.watch(
      instructorDashboardProgressProvider(filter),
    );

    return Scaffold(
      backgroundColor: Colors.black, // 🔥 nền đen
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.black, // 🔥 appbar đen
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Instructor Dashboard",
                style: TextStyle(
                  color: Colors.white, // chữ trắng
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSemesterHeader(overviewAsync),
                    const SizedBox(height: 16),
                    _buildOverviewCards(overviewAsync),
                    const SizedBox(height: 24),
                    _buildFilters(progressAsync),
                    const SizedBox(height: 16),
                    _buildCharts(context, progressAsync),
                    const SizedBox(height: 16),
                    _buildAssignmentTable(progressAsync),
                    const SizedBox(height: 16),
                    _buildQuizTable(progressAsync),
                    const SizedBox(height: 24),
                    _buildExportButtons(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterHeader(AsyncValue<Map<String, dynamic>> overviewAsync) {
    return overviewAsync.when(
      loading: () => Container(
        height: 20,
        width: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
      ).animate().shimmer(duration: 600.ms),
      error: (err, _) =>
          Text("Error: $err", style: const TextStyle(color: Colors.redAccent)),
      data: (data) {
        final semester = data["semester"] as Map<String, dynamic>?;
        final semesterLabel = semester != null
            ? "${semester["code"]} - ${semester["name"]}"
            : "";

        return Text(
          semesterLabel,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildOverviewCards(AsyncValue<Map<String, dynamic>> overviewAsync) {
    return overviewAsync.when(
      loading: () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              2,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).animate().shimmer(duration: 700.ms),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              2,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).animate().shimmer(duration: 700.ms),
              ),
            ),
          ),
        ],
      ),
      error: (err, _) =>
          Text("Error: $err", style: const TextStyle(color: Colors.redAccent)),
      data: (data) {
        final overview = data["overview"] as Map<String, dynamic>?;
        final contents = data["contents"] as Map<String, dynamic>?;

        final totalCourses = overview?["total_courses"] ?? 0;
        final totalGroups = overview?["total_groups"] ?? 0;
        final totalStudents = overview?["total_students"] ?? 0;

        final totalAssignments = contents?["assignments"] ?? 0;
        final totalQuizzes = contents?["quizzes"] ?? 0;
        final totalAnnouncements = contents?["announcements"] ?? 0;
        final totalMaterials = contents?["materials"] ?? 0;

        return Column(
              children: [
                Row(
                  children: [
                    _StatCard(
                      title: "Courses",
                      value: "$totalCourses",
                      icon: Icons.class_,
                      color: Colors.blueAccent,
                    ),
                    _StatCard(
                      title: "Groups",
                      value: "$totalGroups",
                      icon: Icons.group,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatCard(
                      title: "Students",
                      value: "$totalStudents",
                      icon: Icons.school,
                      color: Colors.greenAccent,
                    ),
                    _StatCard(
                      title: "Contents",
                      value:
                          "${totalAssignments + totalQuizzes + totalAnnouncements + totalMaterials}",
                      icon: Icons.library_books,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0)
            .then()
            .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildFilters(AsyncValue<Map<String, dynamic>> progressAsync) {
    // Extract possible course list from data (unique by course_id)
    List<Map<String, dynamic>> courses = [];
    List<Map<String, dynamic>> groups = [];

    progressAsync.whenData((data) {
      final assignList =
          (data["assignments_progress"] as List?)?.cast<Map>() ?? [];
      final quizList = (data["quizzes_progress"] as List?)?.cast<Map>() ?? [];

      final all = [...assignList, ...quizList];

      final byCourseId = <int, Map<String, dynamic>>{};
      for (final raw in all) {
        final m = Map<String, dynamic>.from(raw as Map);
        final id = m["course_id"] as int?;
        if (id != null && !byCourseId.containsKey(id)) {
          byCourseId[id] = {
            "course_id": id,
            "course_name": m["course_name"] ?? "Course $id",
          };
        }
      }
      courses = byCourseId.values.toList();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Filters & Search",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Course dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: DropdownButton<int?>(
                value: _selectedCourseId,
                dropdownColor: Colors.grey.shade900,
                underline: const SizedBox(),
                hint: const Text(
                  "All Courses",
                  style: TextStyle(color: Colors.white70),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      "All Courses",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ...courses.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c["course_id"] as int?,
                      child: Text(
                        c["course_name"]?.toString() ?? "Course",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
              ),
            ),

            // Status dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: DropdownButton<String?>(
                value: _selectedStatus,
                dropdownColor: Colors.grey.shade900,
                underline: const SizedBox(),
                hint: const Text(
                  "All Status",
                  style: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      "All Status",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "submitted",
                    child: Text(
                      "Submitted",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "missing",
                    child: Text(
                      "Missing",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ),

            // Search field
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search assignment/quiz...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _searchText = value.isEmpty ? null : value.trim();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCharts(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> progressAsync,
  ) {
    return progressAsync.when(
      loading: () => SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
              ).animate().shimmer(duration: 700.ms),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
              ).animate().shimmer(duration: 700.ms),
            ),
          ],
        ),
      ),
      error: (err, _) =>
          Text("Error: $err", style: const TextStyle(color: Colors.redAccent)),
      data: (data) {
        final root = Map<String, dynamic>.from(data["data"] ?? {});

        var assignments =
            (root["assignments_progress"] as List?)?.cast<Map>() ?? [];
        var quizzes = (root["quizzes_progress"] as List?)?.cast<Map>() ?? [];


        if (assignments.length < 10) {
          assignments = MockDashboard.assignmentsProgress;
        }

        if (quizzes.length < 10) {
          quizzes = MockDashboard.quizzesProgress;
        }

        final assignList = assignments
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final quizList = quizzes
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Build chart data
        final assignmentBars = <BarChartGroupData>[];
        for (int i = 0; i < assignList.length; i++) {
          final a = assignList[i];
          final submitted = (a["submitted"] ?? 0) as int;
          final total = (a["total_students"] ?? 0) as int;
          final percent = total > 0 ? submitted / total * 100 : 0.0;
          assignmentBars.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: percent,
                  width: 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          );
        }

        int totalAttempted = 0;
        int totalNotAttempted = 0;
        for (final q in quizList) {
          totalAttempted += (q["attempted"] ?? 0) as int;
          totalNotAttempted += (q["not_attempted"] ?? 0) as int;
        }

        final pieSections = <PieChartSectionData>[
          PieChartSectionData(
            value: totalAttempted.toDouble(),
            title: totalAttempted == 0 ? "" : "Attempted",
            radius: 50,
          ),
          PieChartSectionData(
            value: totalNotAttempted.toDouble(),
            title: totalNotAttempted == 0 ? "" : "Not",
            radius: 50,
          ),
        ];

        return Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assignment Completion (%)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) => Text(
                                  "${value.toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: assignmentBars,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quiz Participation",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildAssignmentTable(AsyncValue<Map<String, dynamic>> progressAsync) {
    return progressAsync.when(
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate().shimmer(duration: 700.ms),
      error: (err, _) =>
          Text("Error: $err", style: const TextStyle(color: Colors.redAccent)),
      data: (data) {
        final list = (data["assignments_progress"] as List?)?.cast<Map>() ?? [];
        var assigns = list.map((e) => Map<String, dynamic>.from(e)).toList();

        if (assigns.length < 10) {
          assigns = MockDashboard.assignmentsProgress;
        }

        // Sau khi mock xong nếu vẫn rỗng thì mới báo
        if (assigns.isEmpty) {
          return const Text(
            "No assignment progress data.",
            style: TextStyle(color: Colors.white54),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Assignments Progress",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade900),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStatePropertyAll(
                      Colors.grey.shade800,
                    ),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Course",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Title",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Submitted",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Late",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Missing",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                    rows: assigns.map((a) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              a["course_name"]?.toString() ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              a["title"]?.toString() ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${a["submitted"] ?? 0}",
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${a["late"] ?? 0}",
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${a["not_submitted"] ?? 0}",
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizTable(AsyncValue<Map<String, dynamic>> progressAsync) {
    return progressAsync.when(
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate().shimmer(duration: 700.ms),
      error: (err, _) =>
          Text("Error: $err", style: const TextStyle(color: Colors.redAccent)),
      data: (data) {
final list = (data["quizzes_progress"] as List?)?.cast<Map>() ?? [];
        var quizzes = list.map((e) => Map<String, dynamic>.from(e)).toList();


        // 🟢 Nếu quá ít dữ liệu thì dùng mock để UI đẹp
        if (quizzes.length < 10) {
          quizzes = MockDashboard.quizzesProgress;
        }

        // 🔴 Nếu sau mock mà vẫn rỗng → báo fallback
        if (quizzes.isEmpty) {
          return const Text(
            "No quiz progress data.",
            style: TextStyle(color: Colors.white54),
          );
        }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quizzes Progress",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade900),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStatePropertyAll(
                      Colors.grey.shade800,
                    ),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Course",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Title",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Attempted",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Not Attempted",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Avg Score",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                    rows: quizzes.map((q) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              q["course_name"]?.toString() ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              q["title"]?.toString() ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${q["attempted"] ?? 0}",
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${q["not_attempted"] ?? 0}",
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${q["average_score"] ?? 0}",
                              style: const TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Export Reports",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ExportButton(
              label: "Students CSV",
              icon: Icons.people_alt,
              onTap: () => _exportCsv(context, "students"),
            ),
            _ExportButton(
              label: "Assignments CSV",
              icon: Icons.assignment_outlined,
              onTap: () => _exportCsv(context, "assignment"),
            ),
            _ExportButton(
              label: "Quizzes CSV",
              icon: Icons.quiz_outlined,
              onTap: () => _exportCsv(context, "quiz"),
            ),
            _ExportButton(
              label: "Summary CSV",
              icon: Icons.summarize_outlined,
              onTap: () => _exportCsv(context, "summary"),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.blueAccent.withOpacity(0.15),
        foregroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.4)),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
