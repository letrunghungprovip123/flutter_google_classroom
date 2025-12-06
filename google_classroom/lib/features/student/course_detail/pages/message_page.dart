import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/provider/user_controller.dart';
import './../message_controller.dart';

class MessagePage extends ConsumerStatefulWidget {
  final int conversationId;
  final String? title; // có thể truyền tên giáo viên

  const MessagePage({super.key, required this.conversationId, this.title});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isSending = false;
  List<PlatformFile> _pickedFiles = [];

  @override
  void initState() {
    super.initState();

    // Mark read khi mở màn hình
    Future.microtask(() async {
      try {
        await MessageService.markRead(widget.conversationId);
        // đồng thời refresh messages
        ref.invalidate(messagesProvider(widget.conversationId));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb, // web dùng bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFiles = result.files;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Không chọn được file: $e")));
      }
    }
  }

  Future<List<MultipartFile>> _buildMultipartFiles() async {
    final List<MultipartFile> multipart = [];

    for (final file in _pickedFiles) {
      try {
        if (file.size == 0) continue;

        if (kIsWeb) {
          if (file.bytes == null) continue;

          multipart.add(
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          );
        } else {
          if (file.path == null) continue;

          multipart.add(
            await MultipartFile.fromFile(file.path!, filename: file.name),
          );
        }
      } catch (_) {
        // bỏ qua file lỗi
      }
    }

    return multipart;
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final content = _msgCtrl.text.trim();
    if (content.isEmpty && _pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhập nội dung hoặc chọn file")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final files = await _buildMultipartFiles();

      await MessageService.sendMessage(
        conversationId: widget.conversationId,
        content: content.isEmpty ? null : content,
        files: files.isEmpty ? null : files,
      );

      // Clear input + file
      _msgCtrl.clear();
      setState(() {
        _pickedFiles = [];
      });

      // Refresh messages
      ref.invalidate(messagesProvider(widget.conversationId));

      // Scroll xuống cuối cùng 1 nhịp nhỏ
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (err) {
      String message = "Gửi tin nhắn thất bại";
      if (err is DioException) {
        message = err.response?.data["message"] ?? err.message ?? message;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return "$hh:$mm";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userControllerProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? "Tin nhắn với giáo viên",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: userAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, _) => Center(
                child: Text(
                  "User error: $err",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (user) {
                // print(user);
                final currentUserId = user?.id;
                // print(currentUserId);
                if (currentUserId == null) {
                  return const Center(
                    child: Text(
                      "Không xác định được người dùng",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                return messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      "Lỗi tải tin nhắn: $err",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          "Chưa có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index] as Map;
                        final sender = msg["sender"] as Map?;
                        final senderId = sender?["id"];
                        final isMe = senderId == currentUserId;

                        final content = msg["content"] ?? "";
                        final timeStr = _formatTime(
                          msg["created_at"]?.toString(),
                        );

                        final attachments = (msg["attachments"] as List?) ?? [];

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blueAccent
                                  : Colors.grey.shade800,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(4),
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (content.toString().isNotEmpty)
                                  Text(
                                    content.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),

                                if (attachments.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: attachments
                                        .map((att) {
                                          final a = att as Map;
                                          final fileUrl = a["file_url"];
                                          final fileName =
                                              a["file_name"] ?? "Tập tin";
                                          final fileType = a["file_type"] ?? "";

                                          final isImage =
                                              fileType.startsWith("image/") ||
                                              fileName.toLowerCase().endsWith(
                                                ".jpg",
                                              ) ||
                                              fileName.toLowerCase().endsWith(
                                                ".png",
                                              ) ||
                                              fileName.toLowerCase().endsWith(
                                                ".jpeg",
                                              ) ||
                                              fileName.toLowerCase().endsWith(
                                                ".gif",
                                              );

                                          return GestureDetector(
                                            onTap: () {
                                              if (fileUrl != null) {
                                                launchUrl(Uri.parse(fileUrl));
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black26,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: isImage
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        fileUrl,
                                                        height: 120,
                                                        width: 120,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .insert_drive_file,
                                                          size: 16,
                                                          color: Colors.white70,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          fileName.toString(),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          );

                                        })
                                        .toList()
                                        .cast<Widget>(),
                                  ),
                                ],

                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // preview file đã chọn
          if (_pickedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _pickedFiles[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // chat box
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  // nút chọn file
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white70),
                    onPressed: _isSending ? null : _pickFiles,
                  ),

                  // input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Nhắn tin...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // send
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.lightBlueAccent,
                          ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
