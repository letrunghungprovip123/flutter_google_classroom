class AssignmentModel {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? lateDeadline;
  final bool allowLate;
  final int maxAttempts;
  final int fileSizeLimit;
  final List<AttachmentModel> attachments;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.startDate,
    this.deadline,
    this.lateDeadline,
    required this.allowLate,
    required this.maxAttempts,
    required this.fileSizeLimit,
    required this.attachments,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final att = json["attachments"] as List? ?? [];

    return AssignmentModel(
      id: json["id"],
      courseId: json["course_id"],
      title: json["title"],
      description: json["description"],
      startDate: json["start_date"] != null
          ? DateTime.parse(json["start_date"])
          : null,
      deadline: json["deadline"] != null
          ? DateTime.parse(json["deadline"])
          : null,
      lateDeadline: json["late_deadline"] != null
          ? DateTime.parse(json["late_deadline"])
          : null,
      allowLate: json["allow_late"] ?? false,
      maxAttempts: json["max_attempts"] ?? 1,
      fileSizeLimit: json["file_size_limit_mb"] ?? 10,
      attachments: att.map((a) => AttachmentModel.fromJson(a)).toList(),
    );
  }
}

class AttachmentModel {
  final int id;
  final String fileUrl;
  final String? fileName;

  AttachmentModel({required this.id, required this.fileUrl, this.fileName});

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json["id"],
      fileUrl: json["file_url"],
      fileName: json["file_name"],
    );
  }
}


class AssignmentAttachment {
  final int id;
  final String fileUrl;
  final String fileName;
  final String? fileType;

  AssignmentAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachment(
      id: json['id'],
      fileUrl: json['file_url'],
      fileName: json['file_name'] ?? _detectFileName(json['file_url']),
      fileType: json['file_type'],
    );
  }

  static String _detectFileName(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.last.split('-').last; // lấy "Rubrik.docx"
  }
}
