import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routing/app_router.dart';
import '../../../shared/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool disabled;

  const CourseCard({super.key, required this.course, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (disabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Học kỳ này đã kết thúc, không thể mở lớp học."),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        context.pushNamed(
          AppRoute.studentCourseDetail,
          pathParameters: {'id': course.id.toString()},
          extra: course,
        );
      },
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0, // làm mờ UI
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(course.background),
              fit: BoxFit.cover,
              colorFilter: disabled
                  ? ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    )
                  : null,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  course.teacher,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  course.code,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
