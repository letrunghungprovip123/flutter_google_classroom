import 'package:flutter/material.dart';
import 'package:google_classroom/features/student/dashboard/instructor_dashboard_tab.dart';
import 'package:google_classroom/features/student/dashboard/student_management_page.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<InstructorDashboardPage> createState() =>
      _InstructorDashboardPageState();
}

class _InstructorDashboardPageState extends State<InstructorDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Instructor Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.lightBlueAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.lightBlueAccent,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Student Management"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [InstructorDashboardTab(), StudentManagementTab()],
      ),
    );
  }


}
