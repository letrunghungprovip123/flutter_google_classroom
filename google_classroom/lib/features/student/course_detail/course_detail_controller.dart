import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/dio_client.dart';

final courseDetailProvider = FutureProvider.family((ref, int courseId) async {
  final res = await DioClient.instance.dio.get('/courses/$courseId');
  return res.data['data'];
});

final courseAnnouncementsProvider = FutureProvider.family((
  ref,
  int courseId,
) async {
  final res = await DioClient.instance.dio.get(
    '/announcements',
    queryParameters: {'courseId': courseId},
  );
  return res.data['data'] as List;
});

final getAllStudentsOfCourse = FutureProvider.family((ref, int courseId) async {
  final res = await DioClient.instance.dio.get(
    '/courses/all-student/$courseId',
  );
  return res.data['data'];
});

final groupsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((
  ref,
  courseId,
) async {
  final res = await DioClient.instance.dio.get(
    "/groups",
    queryParameters: {"courseId": courseId},
  );
  return List<Map<String, dynamic>>.from(res.data["data"]);
});

final addStudentToGroupProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, payload) async {
      final courseId = payload["courseId"];
      final groupId = payload["groupId"];
      final studentCode = payload["student_code"];

      await DioClient.instance.dio.post(
        "/groups/student-groups/$groupId",
        data: {"student_code": studentCode},
      );

      // 💥 Reload tất cả nhóm trong khoá học
      ref.invalidate(groupsProvider(courseId));
    });

final removeStudentFromGroupProvider =
    FutureProvider.family<void, Map<String, int>>((ref, payload) async {
      final courseId = payload["courseId"]!;
      final groupId = payload["groupId"]!;
      final studentId = payload["studentId"]!;

      await DioClient.instance.dio.delete(
        "/groups/student-groups/$groupId/$studentId",
      );

      // 💥 Reload tất cả nhóm trong khoá học
      ref.invalidate(groupsProvider(courseId));
    });




final groupCsvLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Preview rows trả về từ backend
class GroupCsvPreviewNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void set(List<Map<String, dynamic>> rows) {
    state = rows;
  }

  void clear() {
    state = [];
  }
}

final groupCsvPreviewProvider =
    NotifierProvider.autoDispose<
      GroupCsvPreviewNotifier,
      List<Map<String, dynamic>>
    >(() => GroupCsvPreviewNotifier());


final previewGroupCsvProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, Map<String, dynamic>>((
      ref,
      args,
    ) async {
      final keepAlive = ref.keepAlive();
      final groupId = args["groupId"] as int;
      final rows = args["rows"] as List<Map<String, dynamic>>;

      // 🔥 TRÌ HOÃN viêc update state Loading
      Future.microtask(() {
        if (ref.mounted) {
          print("⏳ Loading true");
          ref.read(groupCsvLoadingProvider.notifier).state = true;
        }
      });

      print("🚀 Gửi API preview với rows: $rows");

      try {
        final dio = DioClient.instance.dio;
        final res = await dio.post(
          "/groups/student-groups/$groupId/import/preview",
          data: {"rows": rows},
        );

        final list = List<Map<String, dynamic>>.from(res.data["rows"]);

        // 🔥 TRÌ HOÃN update preview state
        Future.microtask(() {
          if (ref.mounted) {
            print("📥 Update preview state: $list");
            ref.read(groupCsvPreviewProvider.notifier).set(list);
            ref.read(groupCsvLoadingProvider.notifier).state = false;
          }
        });

        return list;
      } catch (err) {
        print("❌ Preview API lỗi: $err");

        Future.microtask(() {
          if (ref.mounted) {
            ref.read(groupCsvPreviewProvider.notifier).clear();
            ref.read(groupCsvLoadingProvider.notifier).state = false;
          }
        });

        rethrow;
      } finally {
        print("🧹 Giải phóng keepAlive");
        keepAlive.close();
      }
    });


/// 🚀 Import thật → vào đúng group
final confirmGroupCsvProvider = FutureProvider.family
    .autoDispose<void, Map<String, dynamic>>((ref, args) async {
      final groupId = args["groupId"] as int;
      final rows = args["rows"] as List<Map<String, dynamic>>;

      Future(() => ref.read(groupCsvLoadingProvider.notifier).state = true);

      try {
        final dio = DioClient.instance.dio;
        await dio.post(
          "/groups/student-groups/$groupId/import/confirm",
          data: {"rows": rows},
        );
      } finally {
        Future(() {
          ref.read(groupCsvLoadingProvider.notifier).state = false;
          // Sau khi import xong reload danh sách group
          ref.invalidate(groupsProvider(args["courseId"] as int));
        });
      }
    });

/// 👉 Check đủ điều kiện import
bool canImportGroupCsv(WidgetRef ref) {
  final list = ref.read(groupCsvPreviewProvider);
  return list.isNotEmpty && list.every((e) => e["status"] == "will_add");
}
