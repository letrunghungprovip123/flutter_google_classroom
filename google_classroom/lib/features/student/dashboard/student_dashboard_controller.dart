import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/dio_client.dart';

/// Dashboard tổng quát
final dashboardProvider = FutureProvider.autoDispose((ref) async {
  final dio = DioClient.instance.dio;
  final res = await dio.get("/auth/dashboard");
  return res.data;
});

/// Load danh sách student
final studentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final dio = DioClient.instance.dio;
    final res = await dio.get("/auth/students");

    if (res.data["data"] is List) {
      return List<Map<String, dynamic>>.from(res.data["data"]);
    }
    return [];
  },
);

/// Create 1 student
final createStudentProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, payload) async {
    final dio = DioClient.instance.dio;
    await dio.post("/auth/signup", data: payload);
  },
);

/// ================= CSV IMPORT STATE ===================

/// Preview result list
final csvPreviewProvider =
    NotifierProvider<CsvPreviewNotifier, List<Map<String, dynamic>>>(
      () => CsvPreviewNotifier(),
    );

class CsvPreviewNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setPreview(List<Map<String, dynamic>> rows) => state = rows;
  void clear() => state = [];
}

/// Loading state
final csvImportLoadingProvider = StateProvider<bool>((ref) => false);

/// Preview CSV (API)
final previewCsvRequestProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      List<Map<String, dynamic>>
    >((ref, rows) async {
      final dio = DioClient.instance.dio;

      // CHỈ SET LOADING SAU KHI BUILD XONG
      Future(() {
        ref.read(csvImportLoadingProvider.notifier).state = true;
      });

      try {
        final res = await dio.post(
          "/auth/students/import/preview",
          data: {"rows": rows},
        );

        final list = (res.data["rows"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // UPDATE STATE SAU KHI FUTURE XONG
        Future(() {
          ref.read(csvPreviewProvider.notifier).state = list;
          ref.read(csvImportLoadingProvider.notifier).state = false;
        });

        return list; // 👈 Quan trọng! Trả list để Consumer có thể listen
      } catch (e) {
        Future(() {
          ref.read(csvPreviewProvider.notifier).state = [];
          ref.read(csvImportLoadingProvider.notifier).state = false;
        });
        rethrow;
      }
    });


/// Import CSV thật
final importCsvProvider =
    FutureProvider.family<void, List<Map<String, dynamic>>>((ref, rows) async {
      Future(() {
        ref.read(csvImportLoadingProvider.notifier).state = true;
      });

      try {
        final dio = DioClient.instance.dio;
        await dio.post("/auth/students/import/confirm", data: {"rows": rows});
      } finally {
        Future(() {
          ref.read(csvImportLoadingProvider.notifier).state = false;
          ref.invalidate(studentsProvider); // reload danh sách
        });
      }
    });

/// Cho phép import chưa?
bool canImportStudents(WidgetRef ref) {
  final list = ref.read(csvPreviewProvider);
  return list.isNotEmpty && list.every((row) => row["status"] == "will_create");
}




/// 📌 1️⃣ Overview Dashboard Provider
final instructorDashboardOverviewProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, int>((ref, semesterId) async {
      final dio = DioClient.instance.dio;
      final res = await dio.get(
        "/auth/instructor/dashboard/overview?semesterId=$semesterId",
      );
      return Map<String, dynamic>.from(res.data["data"]);
    });



    class DashboardFilter {
  final int semesterId;
  final int? courseId;
  final int? groupId;
  final String? status;
  final String? search;

  DashboardFilter({
    required this.semesterId,
    this.courseId,
    this.groupId,
    this.status,
    this.search,
  });

  Map<String, dynamic> toQuery() => {
    "semesterId": semesterId,
    if (courseId != null) "courseId": courseId,
    if (groupId != null) "groupId": groupId,
    if (status != null && status!.isNotEmpty) "status": status,
    if (search != null && search!.isNotEmpty) "search": search,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilter &&
          runtimeType == other.runtimeType &&
          semesterId == other.semesterId &&
          courseId == other.courseId &&
          groupId == other.groupId &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode =>
      Object.hash(semesterId, courseId, groupId, status, search);
}


/// 📌 2️⃣ Progress Dashboard Provider (assignments + quizzes + engagement)
final instructorDashboardProgressProvider =
    FutureProvider.family<Map<String, dynamic>, DashboardFilter>((
      ref,
      filter,
    ) async {
      final dio = DioClient.instance.dio;
      final res = await dio.get(
        "/auth/instructor/dashboard/progress",
        queryParameters: filter.toQuery(),
      );
      return Map<String, dynamic>.from(res.data);
    });


/// 📌 3️⃣ CSV Export Provider
final exportCSVProvider = FutureProvider.family
    .autoDispose<
      ({String filename, List<Map<String, dynamic>> rows}),
      Map<String, dynamic>
    >((ref, params) async {
      final dio = DioClient.instance.dio;

      final semesterId = params["semesterId"];
      final type = params["type"]; // students | assignment | quiz | summary

      final res = await dio.get(
        "/auth/instructor/dashboard/export/csv?semesterId=$semesterId&type=$type",
      );

      final rows = (res.data["data"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return (
        filename: (res.data["filename"] as String?) ?? "export.csv",
        rows: rows,
      );
    });
