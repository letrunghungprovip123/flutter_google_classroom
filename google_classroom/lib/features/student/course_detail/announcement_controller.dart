import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/dio_client.dart';

class AnnouncementController extends StateNotifier<AsyncValue<List<dynamic>>> {
  AnnouncementController(this.courseId) : super(const AsyncLoading()) {
    loadAnnouncements();
  }

  final int courseId;

  // -------------------------
  // LOAD ANNOUNCEMENTS
  // -------------------------
  Future<void> loadAnnouncements() async {
    try {
      final res = await DioClient.instance.dio.get(
        '/announcements',
        queryParameters: {'courseId': courseId},
      );
      state = AsyncData(res.data['data']);
      print("state : $state");
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // -------------------------
  // CREATE NEW ANNOUNCEMENT
  // -------------------------
  Future<void> createAnnouncement({
    required String title,
    required String content,
    List<MultipartFile>? files,
  }) async {
    try {
      final form = FormData.fromMap({
        "course_id": courseId,
        "title": title,
        "content": content,
        if (files != null) "files": files,
      });

      final res = await DioClient.instance.dio.post(
        '/announcements',
        data: form,
      );

      final newItem = res.data['data'];

      // Cập nhật state ngay lập tức
      state = state.whenData((list) => [newItem, ...list]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // -------------------------
  // DELETE ANNOUNCEMENT
  // -------------------------
  Future<void> deleteAnnouncement(int id) async {
    try {
      await DioClient.instance.dio.delete('/announcements/$id');

      // cập nhật state
      state = state.whenData(
        (list) => list.where((item) => item["id"] != id).toList(),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// PROVIDER FAMILY
final announcementProvider =
    StateNotifierProvider.family<
      AnnouncementController,
      AsyncValue<List<dynamic>>,
      int
    >((ref, courseId) {
      return AnnouncementController(courseId);
    });
