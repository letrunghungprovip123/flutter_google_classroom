import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/student_dashboard_controller.dart';

class ImportStudentsPage extends ConsumerStatefulWidget {
  const ImportStudentsPage({super.key});

  @override
  ConsumerState<ImportStudentsPage> createState() => _ImportStudentsPageState();
}

class _ImportStudentsPageState extends ConsumerState<ImportStudentsPage> {
  PlatformFile? pickedFile;
  bool isLoading = false;

  List<Map<String, dynamic>> get previewRows => ref.watch(csvPreviewProvider);

  Future<void> pickCsvFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ["csv"],
    );

    if (picked == null) return;

    pickedFile = picked.files.first;
    await _parseAndPreview();
  }

  Future<void> _parseAndPreview() async {
    if (pickedFile == null) return;

    try {
      setState(() => isLoading = true);

      Uint8List bytes = pickedFile!.bytes!;
      final csvString = String.fromCharCodes(bytes);

      final firstLine = csvString.split('\n').first;
      final delimiter = firstLine.contains(';') ? ';' : ',';

      final rows = CsvToListConverter(
        fieldDelimiter: delimiter,
      ).convert(csvString);

      if (rows.isEmpty) return _msg("File CSV trống");

      final header = rows.first.map((e) {
        return e
            .toString()
            .replaceAll("\ufeff", "")
            .replaceAll("\uFEFF", "")
            .trim()
            .toLowerCase();
      }).toList();

      if (header.length < 4) {
        return _msg(
          "CSV phải có đủ 4 cột: full_name, username, email, password",
        );
      }

      if (header[0] != "full_name" ||
          header[1] != "username" ||
          header[2] != "email" ||
          header[3] != "password") {
        return _msg(
          "❌ Sai header CSV. Cần: full_name, username, email, password",
        );
      }

      rows.removeAt(0);

      final parsed = rows.map((r) {
        return {
          "full_name": r.isNotEmpty ? "${r[0]}" : "",
          "username": r.length > 1 ? "${r[1]}" : "",
          "email": r.length > 2 ? "${r[2]}" : "",
          "password": r.length > 3 ? "${r[3]}" : "",
        };
      }).toList();

      await ref.read(previewCsvRequestProvider(parsed).future);
    } catch (e) {
      _msg("Lỗi đọc CSV: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool get canImport =>
      previewRows.isNotEmpty &&
      previewRows.every((row) => row["status"] == "will_create");

  Future<void> _handleImport() async {
    try {
      setState(() => isLoading = true);
      await ref.read(importCsvProvider(previewRows).future);

      _msg("Import thành công!");
      ref.invalidate(studentsProvider);
      Navigator.pop(context, true);
    } catch (e) {
      _msg("Import lỗi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _msg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Import Students CSV",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
            tooltip: "Chọn CSV",
            onPressed: pickCsvFile,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : previewRows.isEmpty
          ? const Center(
              child: Text(
                "📄 Chọn file CSV để xem trước",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : _previewTable(),
      bottomNavigationBar: canImport
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _handleImport,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Import Students",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          : null,
    );
  }

  Widget _previewTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      child: DataTable(
        border: TableBorder.all(color: Colors.white12),
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1C1C1C)),
        dataRowColor: WidgetStateProperty.all(const Color(0xFF242424)),
        columns: const [
          DataColumn(
            label: Text("Full Name", style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text("Username", style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text("Email", style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text("Password", style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text("Status", style: TextStyle(color: Colors.white)),
          ),
        ],
        rows: previewRows.map((r) {
          final status = r["status"] as String;
          final error = r["error"] as String?;

          String displayText =
              error ?? status; // Nếu có error → ưu tiên hiển thị error
          final isErr = status == "error";
          final isDupDB = status == "already_exists";
          final isDupCSV = status == "duplicate";

          Color statusColor = isErr
              ? Colors.redAccent
              : isDupDB
              ? Colors.orangeAccent
              : isDupCSV
              ? Colors.blueAccent
              : Colors.greenAccent;

          return DataRow(
            cells: [
              _cell(r["full_name"]),
              _cell(r["username"]),
              _cell(r["email"]),
              _cell("••••••••"), // hide password
              DataCell(
                Tooltip(
                  message: error ?? "",
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  DataCell _cell(String? text) =>
      DataCell(Text(text ?? "", style: const TextStyle(color: Colors.white)));
}
