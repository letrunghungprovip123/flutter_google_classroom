class MockDashboard {
  static List<Map<String, dynamic>> assignmentsProgress = List.generate(20, (
    i,
  ) {
    return {
      "course_id": i.isEven ? 17 : 8,
      "course_name": i.isEven ? "CTDL & GT" : "Chủ Nghĩa Xã Hội KH",
      "title": "Bài tập #${i + 1}",
      "total_students": 20,
      "submitted": (5 + i) % 20,
      "late": (i % 4),
      "not_submitted": (20 - ((5 + i) % 20) - (i % 4)),
    };
  });

  static List<Map<String, dynamic>> quizzesProgress = List.generate(20, (i) {
    return {
      "course_id": i.isEven ? 17 : 8,
      "course_name": i.isEven ? "CTDL & GT" : "Chủ Nghĩa Xã Hội KH",
      "title": "Quiz #${i + 1}",
      "attempted": (10 + i) % 20,
      "not_attempted": (20 - ((10 + i) % 20)),
      "average_score": 5 + (i % 5).toDouble(), // từ 5 → 9 điểm
    };
  });

  static Map<String, dynamic> engagement = {
    "announcements": List.generate(20, (i) {
      return {
        "id": 100 + i,
        "title": "Thông báo #${i + 1}",
        "viewed_by": (i * 4) % 30,
      };
    }),
    "materials": List.generate(20, (i) {
      return {
        "id": 200 + i,
        "title": "Tài liệu #${i + 1}",
        "viewed_by": (i * 5) % 25,
      };
    }),
  };
}
