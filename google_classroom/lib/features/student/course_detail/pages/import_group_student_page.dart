import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../course_detail_controller.dart';

class ImportGroupStudentsPage extends ConsumerStatefulWidget {
  final int courseId;
  final int groupId;

  const ImportGroupStudentsPage({
    super.key,
    required this.courseId,
    required this.groupId,
  });

  @override
  ConsumerState<ImportGroupStudentsPage> createState() =>
      _ImportGroupStudentsPageState();
}

class _ImportGroupStudentsPageState
    extends ConsumerState<ImportGroupStudentsPage> {
  PlatformFile? pickedFile;

  Future<void> _pickCsv() async {
    print("📌 Bắt đầu chọn file CSV...");
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["csv"],
    );

    if (picked == null) {
      print("⚠️ Không có file được chọn");
      return;
    }

    pickedFile = picked.files.first;
    print("📄 CSV đã chọn: ${pickedFile!.name}");

    _parsePreview();
  }

  Future<void> _parsePreview() async {
    print("🚀 Parse CSV & gọi API preview...");
    try {
      List<List<dynamic>> csvData;

      if (kIsWeb) {
        print("📌 Đang chạy Web");
        final Uint8List bytes = pickedFile!.bytes!;
        csvData = const CsvToListConverter().convert(
          String.fromCharCodes(bytes),
        );
      } else {
        print("📌 Đang chạy Mobile/Desktop");
        final bytes = await pickedFile!.readStream!.toBytes();
        csvData = const CsvToListConverter().convert(
          String.fromCharCodes(bytes),
        );
      }

      print("📊 CSV Rows count (gồm header): ${csvData.length}");

      List<Map<String, dynamic>> rows = [];
      for (int i = 1; i < csvData.length; i++) {
        rows.add({"student_code": csvData[i][0]?.toString().trim() ?? ""});
      }

      print("📬 Gửi request preview lên server với rows: $rows");

      await ref.read(
        previewGroupCsvProvider({
          "groupId": widget.groupId,
          "rows": rows,
        }).future,
      );

      print("🎉 Preview thành công!");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preview thành công")));
    } catch (e) {
      print("❌ Preview lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CSV lỗi định dạng hoặc rỗng!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(groupCsvPreviewProvider);
    final loading = ref.watch(groupCsvLoadingProvider);

    print(
      "🔄 UI rebuild - preview length: ${preview.length} | loading: $loading",
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E), // 🔹 Màu xám tối
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            print("🔙 Back pressed");
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Import sinh viên vào nhóm",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (canImportGroupCsv(ref))
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.greenAccent),
              label: const Text(
                "Xác nhận",
                style: TextStyle(color: Colors.greenAccent),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      print("🚀 Bắt đầu import CSV...");
                      print("📦 Rows import: $preview");
                      try {
                        await ref.read(
                          confirmGroupCsvProvider({
                            "courseId": widget.courseId,
                            "groupId": widget.groupId,
                            "rows": preview,
                          }).future,
                        );

                        print("🎉 Import thành công!");
                        ref.read(groupCsvPreviewProvider.notifier).clear();

                        if (!mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Import thành công")),
                        );
                      } catch (e) {
                        print("❌ Import lỗi: $e");
                        final msg = (e is DioException)
                            ? (e.response?.data["message"] ??
                                  e.message ??
                                  "Import thất bại")
                            : "Import thất bại";
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // 👉 Đẩy sang phải
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_open),
                  label: const Text("Chọn file CSV"),
                  onPressed: loading ? null : _pickCsv,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : preview.isEmpty
                  ? const Center(
                      child: Text(
                        "Chưa có dữ liệu preview",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : _previewTable(preview),
            ),
          ],
        ),
      ),
    );
  }

Widget _previewTable(List<Map<String, dynamic>> rows) {
    print("📌 Render preview table rows: $rows");

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // 👉 Chống tràn ngang
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 600,
            ), // 👌 Full table width
            child: DataTable(
              dividerThickness: 0.3,
              headingRowColor: WidgetStateProperty.all(
                Colors.blueGrey.shade800,
              ),
              dataRowColor: WidgetStateProperty.all(Colors.black54),
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade700,
                  width: .6,
                ),
                verticalInside: BorderSide(
                  color: Colors.grey.shade700,
                  width: .6,
                ),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.white70),
              columns: const [
                DataColumn(label: Text("STT")),
                DataColumn(label: Text("Student Code")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Error")),
              ],
              rows: List.generate(rows.length, (index) {
                final item = rows[index];
                final status = item["status"] ?? "unknown";

                // 🎨 Dynamic color mapping
                Color statusColor = Colors.white70;
                switch (status) {
                  case "will_add":
                    statusColor = Colors.greenAccent;
                    break;
                  case "student_not_found":
                    statusColor = Colors.orangeAccent;
                    break;
                  default:
                    if (status.toString().contains("error")) {
                      statusColor = Colors.redAccent;
                    }
                }

                return DataRow(
                  color: WidgetStateProperty.all(
                    index % 2 == 0 ? Colors.black54 : Colors.black87,
                  ),
                  cells: [
                    DataCell(Text("${index + 1}")), // STT
                    DataCell(Text(item["student_code"] ?? "--")),
                    DataCell(
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    DataCell(Text(item["error"] ?? "")),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

}

extension _ReadStreamExt on Stream<List<int>> {
  Future<Uint8List> toBytes() async {
    final List<List<int>> chunks = [];
    await for (final chunk in this) {
      chunks.add(chunk);
    }
    return Uint8List.fromList(chunks.expand((x) => x).toList());
  }
}
