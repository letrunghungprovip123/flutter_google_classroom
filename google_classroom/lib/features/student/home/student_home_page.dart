import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_classroom/features/student/home/create_course_page.dart';
import '../../../../core/provider/user_controller.dart';
import 'student_home_controller.dart';
import 'widgets/course_card.dart';
import 'student_home_state.dart';

class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<StudentHomePage> {
  bool _autoSelected = false;

bool _isOutOfSemester(String start, String end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final st = DateTime.parse(start);
    final startDate = DateTime(st.year, st.month, st.day);

    final en = DateTime.parse(end);
    final endDate = DateTime(en.year, en.month, en.day);

    return today.isBefore(startDate) || today.isAfter(endDate);
  }


  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userControllerProvider);
    final semestersAsync = ref.watch(semestersProvider);

    final selectedSemesterId = ref.watch(selectedSemesterIdProvider);
    final selectedSemesterCode = ref.watch(selectedSemesterCodeProvider);

    // Lấy role
    final user = userAsync.value;
    final isInstructor = user?.role == "instructor";

    // ===============================
    // 🔥 CHỌN PROVIDER THEO ROLE
    // ===============================
    final asyncCourses =
        (selectedSemesterId == null && selectedSemesterCode == null)
        ? const AsyncValue.loading()
        : (isInstructor)
        ? ref.watch(instructorCoursesProvider(selectedSemesterId))
        : ref.watch(studentCoursesProvider(selectedSemesterCode));

    // LISTENER AUTO CHỌN NGÀY
    ref.listen<AsyncValue<List<dynamic>>>(semestersProvider, (prev, next) {
      if (_autoSelected) return;
      if (!next.hasValue) return;

      final semesters = next.value!;
      if (semesters.isEmpty) return;
      if (ref.read(selectedSemesterIdProvider) != null) return;

      final now = DateTime.now();

      final currentSemester = semesters.firstWhere((s) {
        final st = DateTime.parse(s["start_date"]);
        final en = DateTime.parse(s["end_date"]);
        return now.isAfter(st) && now.isBefore(en);
      }, orElse: () => semesters.first);

      ref.read(selectedSemesterIdProvider.notifier).state =
          currentSemester["id"];
      ref.read(selectedSemesterCodeProvider.notifier).state =
          currentSemester["code"];

      print("🎯 Auto chọn học kỳ: ${currentSemester["code"]}");

      _autoSelected = true;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // ==========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isInstructor ? "Instructor Classroom" : "Classroom",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  context.pushNamed('student_notifications');
                },
              ),
              const SizedBox(width: 20),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: userAsync.when(
                  loading: () => const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  error: (_, __) =>
                      const CircleAvatar(child: Icon(Icons.error)),
                  data: (user) {
                    if (user == null || user.avatarUrl == null) {
                      final letter = (user?.fullName ?? "U")[0].toUpperCase();
                      return CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          letter,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return CircleAvatar(
                      backgroundImage: NetworkImage(user.avatarUrl!),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      // ==========================================================
      body: semestersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text(
            "Lỗi tải học kỳ: $err",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (semesters) {
          if (semesters.isEmpty) return const SizedBox.shrink();

          return asyncCourses.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (err, _) => Center(
              child: Text(
                "Lỗi: $err",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (courses) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSemesterDropdown(semesters, user),
                  const SizedBox(height: 16),

                  ...courses.map((course) {
                    final sem = semesters.firstWhere(
                      (s) => s["id"] == selectedSemesterId,
                    );

                    final disabled = _isOutOfSemester(
                      sem["start_date"],
                      sem["end_date"],
                    );

                    return CourseCard(course: course, disabled: disabled);
                  }),
                ],
              );
            },
          );
        },
      ),

      // ==========================================================
      // 🔥 Floating button dành riêng cho Instructor
      // ==========================================================
      floatingActionButton: isInstructor
          ? Builder(
              builder: (_) {
                // tìm semester hiện tại đang selected
                final sem = semestersAsync.value?.firstWhere(
                  (s) => s["id"] == selectedSemesterId,
                  orElse: () => null,
                );

                // nếu không tìm được hoặc semester đã qua → ẩn button
                if (sem == null ||
                    _isOutOfSemester(sem["start_date"], sem["end_date"])) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    // Chuyển sang trang tạo course
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateCoursePage(),
                      ),
                    );
                  },
                );
              },
            )
          : null,
    );
  }

  void _showCreateSemesterDialog() {
    final _codeCtrl = TextEditingController();
    final _nameCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Thêm Học Kỳ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inputField("Mã học kỳ", _codeCtrl),
                  const SizedBox(height: 10),
                  _inputField("Tên học kỳ", _nameCtrl),
                  const SizedBox(height: 10),

                  _datePicker("Ngày bắt đầu", startDate, (newDate) {
                    setState(() => startDate = newDate);
                  }),

                  const SizedBox(height: 10),

                  _datePicker("Ngày kết thúc", endDate, (newDate) {
                    setState(() => endDate = newDate);
                  }),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("Thêm"),
              onPressed: () async {
                if (_codeCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
                  _showMsg("Vui lòng nhập đầy đủ thông tin!");
                  return;
                }
                if (startDate == null || endDate == null) {
                  _showMsg("Vui lòng chọn ngày!");
                  return;
                }
                if (!startDate!.isBefore(endDate!)) {
                  _showMsg("Ngày bắt đầu phải trước ngày kết thúc!");
                  return;
                }

                try {
                  // GỌI SERVICE TẠO HỌC KỲ
                  final result = await SemesterService.create(
                    code: _codeCtrl.text.trim(),
                    name: _nameCtrl.text.trim(),
                    startDate: startDate!.toIso8601String(),
                    endDate: endDate!.toIso8601String(),
                  );

                  final sem = result["data"];

                  // Refresh state
                  ref.refresh(semestersProvider);

                  // Auto chọn semester vừa tạo
                  ref.read(selectedSemesterIdProvider.notifier).state =
                      sem["id"];
                  ref.read(selectedSemesterCodeProvider.notifier).state =
                      sem["code"];

                  Navigator.pop(context);
                  _showMsg("Thêm học kỳ thành công! 🎉");
                } catch (e) {
                  print(e);
                  _showMsg("Lỗi: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _inputField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? date, Function(DateTime?) cb) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          helpText: label,
        );
        if (picked != null) cb(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          date == null ? label : "$label: ${date.toString().split(' ')[0]}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // DROPDOWN
  Widget _buildSemesterDropdown(List semesters, dynamic user) {
    final selectedSemesterId = ref.watch(selectedSemesterIdProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            "Classes",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),

          if (user != null && user.role == "instructor")
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
              onPressed: _showCreateSemesterDialog,
            ),

          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              value: selectedSemesterId,
              items: semesters.map<DropdownMenuItem<int>>((s) {
                return DropdownMenuItem(
                  value: s["id"],
                  child: Text(
                    s["name"],
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                ref.read(selectedSemesterIdProvider.notifier).state = value;
                ref.read(selectedSemesterCodeProvider.notifier).state =
                    semesters.firstWhere((e) => e["id"] == value)["code"];
              },
            ),
          ),
        ],
      ),
    );
  }
}
