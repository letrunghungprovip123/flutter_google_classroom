import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/course_model.dart';
import './pages/stream_page.dart';
import './pages/assignments_page.dart';
import './pages/people_page.dart';
import './course_detail_controller.dart';

class StudentCourseDetailPage extends ConsumerStatefulWidget {
  final CourseModel course;

  const StudentCourseDetailPage({super.key, required this.course});

  @override
  ConsumerState<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState
    extends ConsumerState<StudentCourseDetailPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // gọi API announcements
    final asyncAnn = ref.watch(courseAnnouncementsProvider(widget.course.id));

    return asyncAnn.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      data: (announcements) {
        // 3 tab chính
        final tabs = [
          StudentStreamPage(
            course: widget.course,
            announcements: announcements,
          ),
          StudentAssignmentsPage(course : widget.course),
          StudentPeoplePage(course: widget.course),
        ];

        return Scaffold(
          backgroundColor: Colors.black,

          // =======================
          // APP BAR CHUNG
          // =======================
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(
              widget.course.name,
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            actions: const [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
            ],
          ),

          // BODY
          body: tabs[_tabIndex],

          // =======================
          // NAV BOTTOM
          // =======================
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            indicatorColor: Colors.blue, // Màu nền khi selected
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // Bo góc
            ),
            backgroundColor: Colors.grey.shade900,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: "Bảng tin",
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined, color: Colors.white),
                label: "Bài tập",
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined, color: Colors.white),
                label: "Mọi người",
              ),
            ],
          ),
        );
      },
    );
  }
}
