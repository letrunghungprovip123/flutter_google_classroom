class SubmissionModel {
  final int id;
  final int assignmentId;
  final int studentId;
  final int attemptNo;
  final String status;
  final DateTime submittedAt;
  final List<SubmissionFile> attachments;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.attemptNo,
    required this.status,
    required this.submittedAt,
    required this.attachments,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> j) {
    return SubmissionModel(
      id: j["id"],
      assignmentId: j["assignment_id"],
      studentId: j["student_id"],
      attemptNo: j["attempt_no"],
      status: j["status"],
      submittedAt: DateTime.parse(j["submitted_at"]),
      attachments: (j["attachments"] as List)
          .map((x) => SubmissionFile.fromJson(x))
          .toList(),
    );
  }
}

class SubmissionFile {
  final String url;
  final String? name;

  SubmissionFile({required this.url, this.name});

  factory SubmissionFile.fromJson(Map<String, dynamic> j) {
    return SubmissionFile(url: j["file_url"], name: j["file_name"]);
  }
}
