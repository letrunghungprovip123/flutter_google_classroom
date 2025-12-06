import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../comment_controller.dart';

class CommentPage extends ConsumerStatefulWidget {
  final int announcementId;
  final int courseId;

  const CommentPage({
    super.key,
    required this.announcementId,
    required this.courseId,
  });

  @override
  ConsumerState<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends ConsumerState<CommentPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // =============================
  // FORMAT TIME
  // =============================
  String formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays == 1) return "Hôm qua";

    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  // =============================
  // SEND COMMENT
  // =============================
  Future<void> _sendComment() async {
    if (_ctrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    // Gửi comment
    await CommentService.createComment(
      announcementId: widget.announcementId,
      content: _ctrl.text.trim(),
    );

    _ctrl.clear();
    setState(() => _isSending = false);

    // Refresh lại provider
    ref.refresh(commentsProvider(widget.announcementId).future);

    await Future.delayed(const Duration(milliseconds: 200));

    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.announcementId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Nhận xét trong lớp học",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // =====================================================
      // COMMENT LIST
      // =====================================================
      body: comments.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text(
            "Lỗi tải bình luận: $err",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (list) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i] as Map<String, dynamic>;

                    final user = c["users"] ?? {};
                    final fullName = user["full_name"] ?? "Người dùng";
                    final avatarUrl = user["avatar_url"];

                    final content = c["content"] ?? "";

                    // Parse thời gian
                    final createdRaw = c["created_at"];
                    final createdAt =
                        DateTime.tryParse(createdRaw) ?? DateTime.now();
                    final time = formatTime(createdAt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ----------------------------------
                          // AVATAR
                          // ----------------------------------
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            backgroundColor: Colors.grey.shade700,
                            child: avatarUrl == null
                                ? Text(
                                    fullName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          // ----------------------------------
                          // COMMENT BUBBLE
                          // ----------------------------------
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // NAME + TIME
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // CONTENT
                                  Text(
                                    content,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // =====================================================
              // INPUT BOX
              // =====================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Thêm nhận xét trong lớp học",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    _isSending
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.blue,
                              size: 28,
                            ),
                            onPressed: _sendComment,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
