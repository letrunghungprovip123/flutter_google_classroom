import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import './notification_controller.dart';
import 'notification_controller.dart';

class StudentNotificationsPage extends ConsumerWidget {
  const StudentNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Thông báo", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("Lỗi: $e", style: const TextStyle(color: Colors.red)),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(
              child: Text(
                "Không có thông báo",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white12),
            itemBuilder: (_, i) {
              final n = notifs[i];
              final isUnread = n["is_read"] == false;

              return GestureDetector(
                onTap: () async {
                  // 🟢 Mark as read ngay lập tức
                  if (isUnread) {
                    await NotificationService.markAsRead(n["id"]);
                    ref.invalidate(notificationsProvider);
                  }

                  // Nếu bạn muốn điều hướng theo loại:
                  // if (n["message"].contains("tài liệu")) ...
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔵 Dot unread
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isUnread
                              ? Colors.blueAccent
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n["title"],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n["message"],
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _fmtDate(n["created_at"]),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
