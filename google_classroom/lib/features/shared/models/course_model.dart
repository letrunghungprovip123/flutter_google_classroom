class CourseModel {
  final int id;
  final String code;
  final String name;
  final String teacher;
  final String background; // ảnh nền — phải truyền từ homepage

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.background,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json, String bg) {
    return CourseModel(
      id: json["id"],
      code: json["code"],
      name: json["name"],
      teacher: json["instructor"]?["full_name"] ?? "",
      background: bg, // nhận ảnh từ homepage
    );
  }
}
