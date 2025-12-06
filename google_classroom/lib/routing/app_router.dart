import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_classroom/core/provider/user_controller.dart';

import 'package:google_classroom/features/auth/presentation/login_page.dart';
import 'package:google_classroom/features/auth/presentation/splash_page.dart';
import 'package:google_classroom/features/shared/models/assignment_model.dart';
import 'package:google_classroom/features/shared/models/course_model.dart';
import 'package:google_classroom/features/student/course_detail/pages/assignment_instructor_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/comment_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/create_page/create_assignment_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/create_page/create_material_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/create_page/create_quiz_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/create_question_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/question_bank_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/question_detail_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/quiz_instructor_detail_page.dart';
import 'package:google_classroom/features/student/course_detail/student_course_detail_page.dart';
import 'package:google_classroom/features/student/dashboard/instructor_dashboard_page.dart';
import 'package:google_classroom/features/student/dashboard/student_dashboard_page.dart';
import 'package:google_classroom/features/student/home/student_home_page.dart';
import 'package:google_classroom/features/student/home/student_notifications_page.dart';
import 'package:google_classroom/features/student/profile/student_profile_page.dart';
import 'package:google_classroom/features/student/shell/student_shell_page.dart';

// DETAIL PAGES
import 'package:google_classroom/features/student/course_detail/pages/assignment_detail_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/quizz_detail.dart';
import 'package:google_classroom/features/student/course_detail/pages/quiz_attempt_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/quiz_result_page.dart';
import 'package:google_classroom/features/student/course_detail/pages/material_detail.dart';

class AppRoute {
  static const splash = '/';
  static const login = '/login';

  static const studentShell = '/student'; // Shell parent
  static const studentHome = '/student/home';
  static const studentProfile = '/student/profile';
  static const studentCourseDetail = 'student_course_detail';
}

Widget _fade(
  BuildContext context,
  Animation<double> a,
  Animation<double> s,
  Widget child,
) {
  return FadeTransition(opacity: a, child: child);
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoute.splash,
  routes: [
    GoRoute(path: AppRoute.splash, builder: (_, __) => const SplashPage()),

    GoRoute(path: AppRoute.login, builder: (_, __) => const LoginPage()),

    ShellRoute(
      builder: (context, state, child) => StudentShellPage(child: child),
      routes: [
        GoRoute(
          path: '/student/home',
          builder: (_, __) => const StudentHomePage(),
        ),
GoRoute(
          path: '/student/dashboard',
          builder: (context, state) {
            return Consumer(
              builder: (context, ref, _) {
                final userAsync = ref.watch(userControllerProvider);
                final user = userAsync.value;

                if (user?.role == "instructor") {
                  return const InstructorDashboardPage();
                }

                return const StudentDashboardPage();
              },
            );
          },
        ),

        GoRoute(
          path: '/student/profile',
          builder: (_, __) => const StudentProfilePage(),
        ),
      ],
    ),

    GoRoute(
      path: '/student/course/:id',
      name: AppRoute.studentCourseDetail,
      builder: (context, state) {
        final course = state.extra as CourseModel;
        return StudentCourseDetailPage(course: course);
      },
    ),

    GoRoute(
      path: '/student/course/:courseId/announcement/:annId/comments',
      name: 'comment_page',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final annId = int.parse(state.pathParameters['annId']!);

        return CustomTransitionPage(
          key: state.pageKey,
          child: CommentPage(announcementId: annId, courseId: courseId),
          transitionsBuilder: (context, animation, secondary, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/student/course/:courseId/assignment/:assignmentId',
      name: 'assignment_detail',
      pageBuilder: (context, state) {
        final assignmentId = int.parse(state.pathParameters['assignmentId']!);

        return CustomTransitionPage(
          key: state.pageKey,
          child: AssignmentDetailPage(assignmentId: assignmentId),
          transitionsBuilder: _fade,
        );
      },
    ),

    GoRoute(
      path: '/instructor/course/:courseId/assignment/:assignmentId/manage',
      name: 'assignment_instructor_detail',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final assignmentId = int.parse(state.pathParameters['assignmentId']!);
        return CustomTransitionPage(
          child: AssignmentInstructorDetailPage(
            // courseId: courseId,
            assignmentId: assignmentId,
          ),
          transitionsBuilder: _fade,
        );
      },
    ),

GoRoute(
      path: '/instructor/course/:courseId/quiz/:quizId',
      name: 'quiz_instructor_detail',
      pageBuilder: (context, state) {
        final quizId = int.parse(state.pathParameters['quizId']!);
        return CustomTransitionPage(
          child: QuizInstructorDetailPage(quizId: quizId),
          transitionsBuilder: _fade,
        );
      },
    ),



    // GoRoute(
    //   path: '/instructor/course/:courseId/assignment/:assignmentId',
    //   name: 'instructor_assignment_detail',
    //   pageBuilder: (context, state) {
    //     final assignmentId = int.parse(state.pathParameters['assignmentId']!);

    //     return CustomTransitionPage(
    //       key: state.pageKey,
    //       child: InstructorAssignmentDetailPage(assignmentId: assignmentId),
    //       transitionsBuilder: _fade,
    //     );
    //   },
    // ),


GoRoute(
      path: '/instructor/course/:courseId/assignment-create',
      name: 'create_assignment',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: CreateAssignmentPage(courseId: courseId),
          transitionsBuilder: _fade,
        );
      },
    ),
GoRoute(
      path: '/instructor/course/:courseId/assignment-edit/:assignmentId',
      name: 'edit_assignment',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final assignmentId = int.parse(state.pathParameters['assignmentId']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: CreateAssignmentPage(
            courseId: courseId,
            assignmentId: assignmentId,
          ),
          transitionsBuilder: _fade,
        );
      },
    ),


    GoRoute(
      path: '/instructor/course/:courseId/material-create',
      name: 'material_create',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);

        return CustomTransitionPage(
          key: state.pageKey,
          child: CreateMaterialPage(courseId: courseId),
          transitionsBuilder: _fade, // hiệu ứng fade bạn đang dùng
        );
      },
    ),

    GoRoute(
      path: "/instructor/course/:courseId/question-bank",
      name: "question_bank",
      builder: (context, state) {
        final id = int.parse(state.pathParameters["courseId"]!);
        return QuestionBankPage(courseId: id);
      },
    ),
GoRoute(
      path: '/instructor/course/:courseId/question-detail',
      name: 'question_detail',
      pageBuilder: (context, state) {
        final question = state.extra as Map<String, dynamic>;

        return CustomTransitionPage(
          key: state.pageKey,
          child: QuestionDetailPage(question: question),
          transitionsBuilder: _fade,
        );
      },
    ),
    
    GoRoute(
      path: '/instructor/course/:courseId/question-create',
      name: 'question_create',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return CustomTransitionPage(
          child: CreateQuestionPage(courseId: courseId),
          transitionsBuilder: _fade,
        );
      },
    ),



GoRoute(
      path: '/instructor/course/:courseId/quiz-create',
      name: 'quiz_create',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return CustomTransitionPage(
          child: CreateQuizPage(courseId: courseId),
          transitionsBuilder: _fade,
        );
      },
    ),


GoRoute(
      path: '/instructor/course/:courseId/quiz-edit/:quizId',
      name: 'quiz_edit',
      pageBuilder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final quizId = int.parse(state.pathParameters['quizId']!);

        return CustomTransitionPage(
          child: CreateQuizPage(
            courseId: courseId,
            quizId: quizId, // ⚡️ Báo hiệu đang Edit
          ),
          transitionsBuilder: _fade,
        );
      },
    ),

    GoRoute(
      path: '/student/course/:courseId/quiz/:quizId',
      name: 'quiz_detail',
      pageBuilder: (context, state) {
        final quizId = int.parse(state.pathParameters['quizId']!);

        return CustomTransitionPage(
          key: state.pageKey,
          child: QuizDetailPage(quizId: quizId),
          transitionsBuilder: _fade,
        );
      },
    ),

    GoRoute(
      path: '/student/course/:courseId/material/:materialId',
      name: 'material_detail',
      pageBuilder: (context, state) {
        final id = int.parse(
          state.pathParameters['materialId']!,
        ); // material object
        return CustomTransitionPage(
          key: state.pageKey,
          child: MaterialDetailPage(materialId: id),
          transitionsBuilder: _fade,
        );
      },
    ),
    GoRoute(
      path: '/student/notifications',
      name: 'student_notifications',
      builder: (_, __) => const StudentNotificationsPage(),
    ),
  ],
);
