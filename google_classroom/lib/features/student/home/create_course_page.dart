import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_home_controller.dart';
import '../../../../core/provider/user_controller.dart';
import 'student_home_state.dart';

class CreateCoursePage extends ConsumerStatefulWidget {
  const CreateCoursePage({super.key});

  @override
  ConsumerState<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends ConsumerState<CreateCoursePage> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  int? _sessions; // 10 hoặc 15
  int _groupCount = 1;

  final List<TextEditingController> _groupCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final selectedSemesterId = ref.watch(selectedSemesterIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Create Course",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInput("Course Name", _nameCtrl),
            const SizedBox(height: 16),

            _buildInput("Course Code", _codeCtrl),
            const SizedBox(height: 16),

            // Sessions dropdown
            _buildDropdown<int>(
              label: "Sessions",
              value: _sessions,
              items: const [10, 15],
              onChanged: (v) => setState(() => _sessions = v),
            ),

            const SizedBox(height: 20),

            // Group count dropdown
            _buildDropdown<int>(
              label: "Number of Groups",
              value: _groupCount,
              items: const [1, 2, 3],
              onChanged: (v) => setState(() => _groupCount = v!),
            ),

            const SizedBox(height: 20),

            // Group name fields
            for (int i = 0; i < _groupCount; i++)
              _buildInput("Group ${i + 1} Name", _groupCtrls[i]),

            const SizedBox(height: 30),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () => _createCourse(selectedSemesterId),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Course"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 FUNCTION CREATE COURSE
  // ============================================================
  Future<void> _createCourse(int? semesterId) async {
    if (_nameCtrl.text.isEmpty || _codeCtrl.text.isEmpty || _sessions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final groups = List.generate(
      _groupCount,
      (i) => {"name": _groupCtrls[i].text.trim()},
    );

    final payload = {
      "name": _nameCtrl.text.trim(),
      "code": _codeCtrl.text.trim(),
      "semester_id": semesterId,
      "sessions": _sessions,
      "groups": groups,
    };

    try {
      setState(() => loading = true);

      final result = await ref.read(createCourseProvider(payload).future);

      // Thành công
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"] ?? "Created")));

      Navigator.pop(context); // quay lại homepage

      // Force reload course list
      ref.invalidate(instructorCoursesProvider);
      ref.invalidate(studentCoursesProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  // ============================================================
  // UI HELPERS
  // ============================================================
  Widget _buildInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1E1E1E),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white),
        hint: Text(label, style: const TextStyle(color: Colors.white54)),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
