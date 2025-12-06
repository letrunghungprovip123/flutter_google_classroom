import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_classroom/features/student/dashboard/import_csv_page.dart';
import '../../../../../core/provider/user_controller.dart';
import './student_dashboard_controller.dart';

class StudentManagementTab extends ConsumerWidget {
  const StudentManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudents = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Student Management",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: "Import CSV",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportStudentsPage()),
              );

              if (result == true) {
                // 🔥 Làm mới danh sách sinh viên
                ref.invalidate(studentsProvider);
              }
            },

            icon: const Icon(Icons.upload_file, color: Colors.orangeAccent),
          ),
          IconButton(
            tooltip: "Add Student",
            onPressed: () async {
              final formData = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => const _AddStudentDialog(),
              );

              if (formData == null) return;

              try {
                await ref.read(createStudentProvider(formData).future);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Student created successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                ref.invalidate(studentsProvider); // 🔥 Reload bảng ngay
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_add, color: Colors.greenAccent),
          ),
        ],
      ),
      body: asyncStudents.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text(
            "Error: $e",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Text(
                "No Students Found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
              border: TableBorder.all(color: Colors.white24),
              columnSpacing: 30,
              columns: [
                DataColumn(label: _header("Avatar")),
                DataColumn(label: _header("Full Name")),
                DataColumn(label: _header("Student Code")),
                DataColumn(label: _header("Email")),
                DataColumn(label: _header("Year")),
              ],
              rows: students.map<DataRow>((s) {
                final user = s["users"] ?? {};
                final avatar = user["avatar_url"] ?? "";
                final name = user["full_name"] ?? "Student";

                return DataRow(
                  cells: [
                    DataCell(
                      (avatar.isEmpty)
                          ? CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.greenAccent,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(avatar),
                            ),
                    ),
                    DataCell(_cell(name)),
                    DataCell(_cell(s["student_code"] ?? "N/A")),
                    DataCell(_cell(user["email"] ?? "")),
                    DataCell(_cell(s["year"]?.toString() ?? "-")),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  static Text _header(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );

  static Text _cell(String text) =>
      Text(text, style: const TextStyle(color: Colors.white));
}

/// Dialog nhập thông tin để tạo student
class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        "Add Student",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Username", _usernameCtrl),
            const SizedBox(height: 10),
            _field("Email", _emailCtrl, email: true),
            const SizedBox(height: 10),
            _field("Password", _passwordCtrl, password: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                "username": _usernameCtrl.text.trim(),
                "email": _emailCtrl.text.trim(),
                "password": _passwordCtrl.text.trim(),
                "role": "student",
              });
            }
          },
          child: const Text("Add", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool email = false,
    bool password = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: password,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? "$label required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}
