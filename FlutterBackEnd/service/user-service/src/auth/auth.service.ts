import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { RpcException } from '@nestjs/microservices';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { mapPrismaError } from 'src/common/utils/prisma-error.util';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  private readonly JWT_SECRET = process.env.JWT_SECRET || 'my_secret_key';
  private readonly JWT_EXPIRE = '7d';

  // ---------------------------
  // Đăng ký
  // ---------------------------
  async signup(data: {
    username: string;
    email: string;
    password: string;
    // role?: string; // ❌ bỏ luôn, tránh cho FE gửi linh tinh
  }) {
    try {
      // ❌ Không cho trùng username / email
      const existed = await this.prisma.users.findFirst({
        where: {
          OR: [{ username: data.username }, { email: data.email }],
        },
      });

      if (existed) {
        throw new RpcException({
          statusCode: 400,
          message: 'Username hoặc email đã tồn tại',
        });
      }

      const hash = await bcrypt.hash(data.password, 10);
      const currentYear = new Date().getFullYear();

      // ✅ Transaction: tạo user + student cùng lúc
      const result = await this.prisma.$transaction(async (tx) => {
        // 1. Tạo user (luôn là student)
        const user = await tx.users.create({
          data: {
            username: data.username,
            email: data.email,
            password_hash: hash,
            full_name: data.username, // có thể cho FE truyền full_name riêng nếu muốn
            role: 'student', // 🔒 fix cứng theo đề
          },
        });

        // 2. Tạo student mapping với user vừa tạo
        const student = await tx.students.create({
          data: {
            user_id: user.id,
            // VD: 522H001, 522H002, ...
            student_code: `522H00${user.id}`,
            year: currentYear,
          },
        });

        return { user, student };
      });

      return {
        message: 'Đăng ký student thành công',
        data: {
          user: {
            id: result.user.id,
            username: result.user.username,
            email: result.user.email,
            role: result.user.role,
          },
          student: {
            id: result.student.id,
            student_code: result.student.student_code,
            year: result.student.year,
          },
        },
      };
    } catch (err) {
      // Nếu đã là RpcException thì giữ nguyên
      if (err instanceof RpcException) throw err;

      throw new RpcException({
        statusCode: 500,
        message: err.message || 'Lỗi server khi đăng ký student',
      });
    }
  }

  async getDashboardInstructor(
    instructorId: number,
    semesterId?: number | null,
  ) {
    // 1️⃣ Lấy semester hiện tại nếu không truyền
    let currentSemester = null;

    if (semesterId) {
      currentSemester = await this.prisma.semesters.findUnique({
        where: { id: semesterId },
      });
    } else {
      currentSemester = await this.prisma.semesters.findFirst({
        orderBy: { id: 'desc' }, // Lấy học kỳ mới nhất
      });
    }

    if (!currentSemester) {
      throw new Error('No semester found');
    }

    const sid = currentSemester.id;

    // 2️⃣ Đếm courses do instructor dạy trong học kỳ
    const courses = await this.prisma.courses.findMany({
      where: {
        instructor_id: instructorId,
        semester_id: sid,
      },
      select: { id: true },
    });

    const courseIds = courses.map((c) => c.id);

    // 3️⃣ Query tổng hợp song song tăng tốc
    const [
      totalGroups,
      totalStudents,
      announcementsCount,
      assignmentsCount,
      quizzesCount,
      materialsCount,
    ] = await Promise.all([
      this.prisma.groups.count({
        where: { course_id: { in: courseIds } },
      }),
      this.prisma.student_groups.count({
        where: { group_id: { not: null } },
      }),
      this.prisma.announcements.count({
        where: { course_id: { in: courseIds } },
      }),
      this.prisma.assignments.count({
        where: { course_id: { in: courseIds } },
      }),
      this.prisma.quizzes.count({
        where: { course_id: { in: courseIds } },
      }),
      this.prisma.materials.count({
        where: { course_id: { in: courseIds } },
      }),
    ]);

    return {
      message: 'Instructor Dashboard Success',
      data: {
        semester: currentSemester,
        overview: {
          total_courses: courseIds.length,
          total_groups: totalGroups,
          total_students: totalStudents,
        },
        contents: {
          announcements: announcementsCount,
          assignments: assignmentsCount,
          quizzes: quizzesCount,
          materials: materialsCount,
        },
      },
    };
  }

  async getDashboardProgress(payload: {
    instructorId: number;
    semesterId?: number | null;
    courseId?: number | null;
    groupId?: number | null;
    status?: string;
    search?: string;
  }) {
    const { instructorId, semesterId, courseId, groupId, status, search } =
      payload;

    // 1️⃣ Determine semester (fallback: latest)
    let semester = semesterId
      ? await this.prisma.semesters.findUnique({ where: { id: semesterId } })
      : await this.prisma.semesters.findFirst({ orderBy: { id: 'desc' } });

    const sid = semester.id;

    // 2️⃣ Get course IDs taught by instructor in this semester
    const courses = await this.prisma.courses.findMany({
      where: {
        instructor_id: instructorId,
        semester_id: sid,
        ...(courseId && { id: courseId }),
      },
      select: { id: true },
    });
    const courseIds = courses.map((c) => c.id);

    // 3️⃣ Filter students by group if selected
    let groupStudentIds: number[] | null = null;
    if (groupId) {
      const groupStudents = await this.prisma.student_groups.findMany({
        where: { group_id: groupId },
        select: { student_id: true },
      });
      groupStudentIds = groupStudents.map((s) => s.student_id);
    }

    // 4️⃣ Assignments Progress
    const assignments = await this.prisma.assignments.findMany({
      where: {
        course_id: { in: courseIds },
        ...(search && { title: { contains: search, mode: 'insensitive' } }),
      },
      include: {
        courses: true,
        submissions: groupStudentIds
          ? { where: { student_id: { in: groupStudentIds } } }
          : true,
      },
    });

    const assignmentsProgress = assignments
      .map((a) => {
        const total = groupStudentIds
          ? groupStudentIds.length
          : a.submissions.length;

        const submitted = a.submissions.filter(
          (s) => s.file_url !== null,
        ).length;
        const late = a.submissions.filter((s) => s.status === 'late').length;
        const notSubmitted = total - submitted;

        if (status === 'submitted' && submitted === 0) return null;
        if (status === 'missing' && notSubmitted === 0) return null;

        return {
          assignment_id: a.id,
          course_id: a.courses?.id,
          course_name: a.courses?.name,
          title: a.title,
          total_students: total,
          submitted,
          late,
          not_submitted: notSubmitted,
        };
      })
      .filter(Boolean);

    // 5️⃣ Quizzes Progress
    const quizzes = await this.prisma.quizzes.findMany({
      where: {
        course_id: { in: courseIds },
        ...(search && { title: { contains: search, mode: 'insensitive' } }),
      },
      include: {
        courses: true,
        quiz_attempts: groupStudentIds
          ? { where: { student_id: { in: groupStudentIds } } }
          : true,
      },
    });

    const quizzesProgress = quizzes.map((q) => {
      const attempted = q.quiz_attempts.filter(
        (qa) => qa.score !== null,
      ).length;
      const total = groupStudentIds
        ? groupStudentIds.length
        : q.quiz_attempts.length;
      const notAttempted = total - attempted;
      const avgScore =
        attempted > 0
          ? q.quiz_attempts.reduce(
              (sum, qa) => sum + Number(qa.score || 0),
              0,
            ) / attempted
          : 0;

      return {
        quiz_id: q.id,
        course_id: q.courses?.id,
        course_name: q.courses?.name,
        title: q.title,
        attempted,
        not_attempted: notAttempted,
        average_score: Number(avgScore.toFixed(2)),
      };
    });

    // 6️⃣ Engagement tracking (Announcement + Materials)
    const [announcementEng, materialEng] = await Promise.all([
      this.prisma.announcements.findMany({
        where: { course_id: { in: courseIds } },
        include: { views: true },
      }),
      this.prisma.materials.findMany({
        where: { course_id: { in: courseIds } },
        include: { views: true },
      }),
    ]);

    return {
      message: 'Instructor Dashboard Progress Success',
      data: {
        assignments_progress: assignmentsProgress,
        quizzes_progress: quizzesProgress,
        engagement: {
          announcements: announcementEng.map((a) => ({
            id: a.id,
            title: a.title,
            viewed_by: a.views.length,
          })),
          materials: materialEng.map((m) => ({
            id: m.id,
            title: m.title,
            viewed_by: m.views.length,
          })),
        },
      },
    };
  }

  async exportDashboardCSV(payload: {
    instructorId: number;
    semesterId: number;
    type: string;
  }) {
    const { instructorId, semesterId, type } = payload;

    const semester = await this.prisma.semesters.findUnique({
      where: { id: semesterId },
    });

    const courses = await this.prisma.courses.findMany({
      where: {
        instructor_id: instructorId,
        semester_id: semesterId,
      },
      include: {
        groups: {
          include: {
            student_groups: {
              include: {
                students: {
                  include: {
                    users: true,
                  },
                },
              },
            },
          },
        },
        assignments: true,
        quizzes: true,
      },
    });

    if (!courses.length) {
      return { message: 'No data to export', data: [] };
    }

    switch (type) {
      case 'students': {
        const rows: any[] = [];

        for (const c of courses) {
          for (const g of c.groups) {
            for (const sg of g.student_groups) {
              rows.push({
                course: c.name,
                group: g.name,
                student_code: sg.students.student_code,
                full_name: sg.students.users.full_name,
                email: sg.students.users.email,
              });
            }
          }
        }
        return {
          filename: `students_semester_${semester.code}.csv`,
          data: rows,
        };
      }

      case 'assignment': {
        const rows: any[] = [];

        for (const c of courses) {
          for (const a of c.assignments) {
            const submissions = await this.prisma.submissions.count({
              where: { assignment_id: a.id },
            });

            rows.push({
              course: c.name,
              assignment: a.title,
              submitted: submissions,
              total_students: c.groups.flatMap((g) =>
                g.student_groups.map((sg) => sg.student_id),
              ).length,
            });
          }
        }

        return {
          filename: `assignments_progress_${semester.code}.csv`,
          data: rows,
        };
      }

      case 'quiz': {
        const rows: any[] = [];

        for (const c of courses) {
          for (const q of c.quizzes) {
            const attempts = await this.prisma.quiz_attempts.findMany({
              where: { quiz_id: q.id },
            });

            const attempted = attempts.filter((a) => a.score !== null).length;
            const avg =
              attempted > 0
                ? attempts.reduce((sum, a) => sum + Number(a.score ?? 0), 0) /
                  attempted
                : 0;

            rows.push({
              course: c.name,
              quiz: q.title,
              attempted,
              average_score: avg.toFixed(2),
            });
          }
        }

        return {
          filename: `quiz_progress_${semester.code}.csv`,
          data: rows,
        };
      }

      case 'summary': {
        return {
          filename: `semester_summary_${semester.code}.csv`,
          data: [
            {
              semester: semester.name,
              courses: courses.length,
              students: courses.reduce(
                (sum, c) =>
                  sum +
                  c.groups.reduce(
                    (gsum, g) => gsum + g.student_groups.length,
                    0,
                  ),
                0,
              ),
            },
          ],
        };
      }
    }

    return { message: 'Invalid type' };
  }

  // ---------------------------
  // Đăng nhập
  // ---------------------------
  async login(data: { username: string; password: string }) {
    try {
      const user = await this.prisma.users.findFirst({
        where: { username: data.username },
      });

      if (!user)
        throw new RpcException({
          statusCode: 404,
          message: 'Tài khoản không tồn tại',
        });

      const match = await bcrypt.compare(data.password, user.password_hash);
      if (!match)
        throw new RpcException({ statusCode: 400, message: 'Sai mật khẩu' });

      const token = jwt.sign(
        {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role,
        },
        this.JWT_SECRET,
        { expiresIn: this.JWT_EXPIRE },
      );

      return {
        message: 'Đăng nhập thành công',
        data: {
          token,
          user: { id: user.id, username: user.username, role: user.role },
        },
      };
    } catch (err) {
      // ✅ Giữ nguyên lỗi RpcException (statusCode gốc)
      if (err instanceof RpcException) throw err;

      throw new RpcException({
        statusCode: 500,
        message: err.message || 'Lỗi server khi đăng nhập',
      });
    }
  }
  async previewCsv(rows: any[]) {
    const result = [];
    const seenUsername = new Set();
    const seenEmail = new Set();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    for (const row of rows) {
      const { full_name, username, email, password } = row;

      // 1️⃣ Missing fields
      if (!username || !email || !password) {
        result.push({
          ...row,
          status: 'error',
          error: 'Thiếu username/email/password',
        });
        continue;
      }

      // 2️⃣ Invalid email format
      if (!emailRegex.test(email)) {
        result.push({
          ...row,
          status: 'error',
          error: 'Email định dạng không hợp lệ',
        });
        continue;
      }

      // 3️⃣ Password length minimum rule
      if (String(password).length < 6) {
        result.push({
          ...row,
          status: 'error',
          error: 'Password phải ít nhất 6 ký tự',
        });
        continue;
      }

      // 4️⃣ Duplicate inside CSV
      if (seenUsername.has(username) || seenEmail.has(email)) {
        result.push({
          ...row,
          status: 'duplicate',
          error: 'Trùng username/email trong chính file CSV',
        });
        continue;
      }

      seenUsername.add(username);
      seenEmail.add(email);

      // 5️⃣ Duplicate inside Database
      const existed = await this.prisma.users.findFirst({
        where: {
          OR: [{ email }, { username }],
        },
      });

      if (existed) {
        result.push({
          ...row,
          status: 'already_exists',
          error: 'Username hoặc email đã tồn tại trong hệ thống',
        });
        continue;
      }

      // 6️⃣ OK
      result.push({
        ...row,
        status: 'will_create',
      });
    }

    return {
      message: 'Preview CSV success',
      rows: result,
    };
  }

  async bulkSignup(rows: any[]) {
    const currentYear = new Date().getFullYear();
    const results = [];

    for (const s of rows) {
      try {
        const existed = await this.prisma.users.findFirst({
          where: {
            OR: [{ username: s.username }, { email: s.email }],
          },
        });

        if (existed) {
          results.push({ ...s, status: 'skipped_already_exists' });
          continue;
        }

        const hash = await bcrypt.hash(String(s.password ?? s.username), 10);

        const created = await this.prisma.$transaction(async (tx) => {
          const user = await tx.users.create({
            data: {
              username: s.username,
              email: s.email,
              full_name: s.full_name ?? s.username,
              password_hash: hash,
              role: 'student',
            },
          });

          const student = await tx.students.create({
            data: {
              user_id: user.id,
              student_code: `522H00${user.id}`,
              year: currentYear,
            },
          });

          return { user, student };
        });

        results.push({
          ...s,
          status: 'created',
          student_code: created.student.student_code,
        });
      } catch (err) {
        results.push({
          ...s,
          status: 'failed',
          error: err.message,
        });
      }
    }

    return {
      message: 'Bulk signup completed',
      results,
    };
  }

  async getAllStudents() {
    const data = await this.prisma.students.findMany({
      include: {
        users: true,
      },
      orderBy: { id: 'asc' },
    });

    return { message: 'OK', data };
  }

  async deleteStudent(id: number) {
    try {
      await this.prisma.students.delete({
        where: { id },
      });

      return { message: 'Deleted student successfully' };
    } catch (err) {
      throw new RpcException({
        statusCode: 400,
        message: 'Không tìm thấy student hoặc lỗi khi xóa',
      });
    }
  }

  // ---------------------------
  // Lấy thông tin profile từ JWT token
  // ---------------------------
  async profile(token: string) {
    // console.log(token);
    try {
      const decoded = jwt.verify(token, this.JWT_SECRET) as any;
      // console.log(decoded);
      const user = await this.prisma.users.findFirst({
        where: { id: decoded.id },
      });

      if (!user)
        throw new RpcException({
          statusCode: 404,
          message: 'User không tồn tại',
        });

      return { message: 'Thông tin user', data: user };
    } catch (err) {
      // ✅ Nếu token lỗi hoặc hết hạn
      if (
        err.name === 'TokenExpiredError' ||
        err.name === 'JsonWebTokenError'
      ) {
        throw new RpcException({
          statusCode: 401,
          message: 'Token không hợp lệ hoặc đã hết hạn',
        });
      }

      // ✅ Giữ nguyên RpcException (nếu đã có statusCode gốc)
      if (err instanceof RpcException) throw err;

      // ✅ Mặc định lỗi server
      throw new RpcException({
        statusCode: 500,
        message: err.message || 'Lỗi server khi lấy profile',
      });
    }
  }

  async updateProfile(userId: number, file: any, body: any) {
    // 1. Lấy user hiện tại

    try {
      const user = await this.prisma.users.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new RpcException({
          statusCode: 404,
          message: 'User không tồn tại',
        });
      }

      // 2. Chuẩn bị data update
      const updateData: any = {};

      // ============================
      // ❌ Không cho sửa các trường cấm
      // ============================
      if (body.username || body.full_name || body.role) {
        throw new RpcException({
          statusCode: 400,
          message:
            'Bạn không được phép chỉnh sửa username, full_name hoặc role',
        });
      }

      // ============================
      // ✔ Xử lý đổi mật khẩu nếu có
      // ============================
      if (body.new_password) {
        if (!body.old_password) {
          throw new RpcException({
            statusCode: 400,
            message: 'Vui lòng nhập mật khẩu cũ để đổi mật khẩu',
          });
        }

        // Kiểm tra old_password
        const match = await bcrypt.compare(
          body.old_password,
          user.password_hash,
        );
        if (!match) {
          throw new RpcException({
            statusCode: 400,
            message: 'Mật khẩu cũ không chính xác',
          });
        }

        // Hash mật khẩu mới
        const hashed = await bcrypt.hash(body.new_password, 10);
        updateData.password_hash = hashed;
      }

      // ============================
      // ✔ Cho phép sửa email (nếu muốn)
      // ============================
      if (body.email) {
        updateData.email = body.email;
      }

      // ============================
      // ✔ Upload avatar nếu có file
      // ============================
      if (file) {
        // NestJS nhận file từ multer nên file.buffer là Buffer trực tiếp
        const buffer = file.buffer?.data
          ? Buffer.from(file.buffer.data)
          : file.buffer;

        const result = await this.cloudinaryService.uploadAvatar(
          buffer,
          file.originalname,
          file.mimetype,
        );

        updateData.avatar_url = result.secure_url;
      }

      // ============================
      // 5. Update DB
      // ============================
      const updated = await this.prisma.users.update({
        where: { id: userId },
        data: updateData,
        select: {
          id: true,
          username: true,
          full_name: true,
          email: true,
          avatar_url: true,
          role: true,
        },
      });

      return {
        message: 'Cập nhật hồ sơ thành công',
        data: updated,
      };
    } catch (err) {
      if (err instanceof RpcException) throw err;

      // ✅ Lỗi hệ thống thật
      throw new RpcException({
        statusCode: 500,
        message: err.message || 'Lỗi server khi đăng ký',
      });
    }
  }

  async getDashboard(user_id: number) {
    try {
      // ==========================================================
      // 1️⃣ Lấy user + student record
      // ==========================================================
      const user = await this.prisma.users.findFirst({
        where: { id: user_id },
        include: { students: true },
      });

      if (!user)
        throw new RpcException({
          statusCode: 404,
          message: 'User không tồn tại',
        });

      const isStudent = user.role === 'student';
      const isInstructor = user.role === 'instructor';

      if (!isStudent && !isInstructor)
        throw new RpcException({
          statusCode: 400,
          message: 'Vai trò không hợp lệ',
        });

      const now = new Date();

      // =================================================================
      // ========================= 2️⃣ STUDENT ============================
      // =================================================================
      // =========================================================
      // ========================= STUDENT =======================
      // =========================================================
      if (isStudent) {
        const student = user.students?.[0];
        if (!student)
          throw new RpcException({
            statusCode: 400,
            message: 'User không phải student hợp lệ',
          });

        const student_id = student.id;
        const now = new Date();

        // 1️⃣ Lấy tất cả courses student đang học
        const enrolledGroups = await this.prisma.student_groups.findMany({
          where: { student_id },
          include: {
            groups: {
              include: { courses: true },
            },
          },
        });

        const courseIds = [
          ...new Set(enrolledGroups.map((g) => g.groups.course_id)),
        ];

        // 2️⃣ Lấy ALL assignments + submissions liên quan
        const assignments = await this.prisma.assignments.findMany({
          where: { course_id: { in: courseIds } },
          include: {
            submissions: true,
            courses: true,
          },
        });

        // =======================================================
        // =============== Submitted Assignments ==================
        // =======================================================
        const submittedAssignments = assignments
          .filter((a) => a.submissions.some((s) => s.student_id === student_id))
          .map((a) => {
            const sub = a.submissions.find((s) => s.student_id === student_id);
            return {
              assignmentId: a.id,
              title: a.title,
              courseId: a.course_id,
              courseName: a.courses.name,
              submittedAt: sub.submitted_at,
              grade: sub.grade,
              status: sub.submitted_at <= a.deadline ? 'on_time' : 'late',
            };
          });

        // =======================================================
        // ================= Pending Assignments ==================
        // =======================================================
        const pendingAssignments = assignments
          .filter(
            (a) =>
              !a.submissions.some((s) => s.student_id === student_id) &&
              a.deadline &&
              now <= a.deadline,
          )
          .map((a) => ({
            assignmentId: a.id,
            title: a.title,
            courseId: a.course_id,
            courseName: a.courses.name,
            deadline: a.deadline,
          }));

        // =======================================================
        // ================== Late Assignments ====================
        // =======================================================
        const lateAssignments = [];

        for (const a of assignments) {
          const sub = a.submissions.find((s) => s.student_id === student_id);

          if (sub) {
            // Đã nộp nhưng TRỄ
            if (a.deadline && sub.submitted_at > a.deadline) {
              lateAssignments.push({
                assignmentId: a.id,
                title: a.title,
                courseId: a.course_id,
                courseName: a.courses.name,
                submittedAt: sub.submitted_at,
                deadline: a.deadline,
              });
            }
          } else {
            // Chưa nộp → kiểm tra deadline
            if (!a.allow_late) {
              // KHÔNG ALLOW LATE → quá deadline là late
              if (a.deadline && now > a.deadline) {
                lateAssignments.push({
                  assignmentId: a.id,
                  title: a.title,
                  courseId: a.course_id,
                  courseName: a.courses.name,
                  deadline: a.deadline,
                });
              }
            } else {
              // ALLOW LATE → check late_deadline
              if (a.late_deadline && now > a.late_deadline) {
                lateAssignments.push({
                  assignmentId: a.id,
                  title: a.title,
                  courseId: a.course_id,
                  courseName: a.courses.name,
                  deadline: a.deadline,
                  lateDeadline: a.late_deadline,
                });
              }
            }
          }
        }

        // =======================================================
        // ================== Completed Quizzes ===================
        // =======================================================
        const quizAttempts = await this.prisma.quiz_attempts.findMany({
          where: { student_id },
          include: { quizzes: true },
        });

        const completedQuizzes = quizAttempts.map((q) => ({
          quizId: q.quiz_id,
          title: q.quizzes.title,
          courseId: q.quizzes.course_id,
          score: q.score,
          submittedAt: q.submitted_at,
        }));

        // =======================================================
        // ================= Upcoming Deadlines ===================
        // =======================================================
        const quizzes = await this.prisma.quizzes.findMany({
          where: { course_id: { in: courseIds } },
        });

        const upcomingDeadlines = [];

        // ================= ASSIGNMENTS UPCOMING =================
        // Chỉ lấy assignment CHƯA NỘP
        assignments.forEach((a) => {
          const hasSubmitted = a.submissions.some(
            (s) => s.student_id === student_id,
          );

          if (!hasSubmitted && a.deadline && now < a.deadline) {
            upcomingDeadlines.push({
              type: 'assignment',
              id: a.id,
              title: a.title,
              courseId: a.course_id,
              courseName: a.courses.name,
              deadline: a.deadline,
            });
          }
        });

        // ================= QUIZZES UPCOMING =================
        // Chỉ lấy quiz CHƯA LÀM
        quizzes.forEach((q) => {
          const hasAttempted = quizAttempts.some(
            (attempt) => attempt.quiz_id === q.id,
          );

          if (!hasAttempted && q.close_time && now < q.close_time) {
            upcomingDeadlines.push({
              type: 'quiz',
              id: q.id,
              title: q.title,
              courseId: q.course_id,
              closeTime: q.close_time,
            });
          }
        });

        // SORT tăng dần theo deadline
        upcomingDeadlines.sort(
          (a, b) =>
            new Date(a.deadline || a.closeTime).getTime() -
            new Date(b.deadline || b.closeTime).getTime(),
        );

        // =======================================================
        // ======================= OVERVIEW =======================
        // =======================================================
        const overview = {
          totalCourses: courseIds.length,
          totalSubmittedAssignments: submittedAssignments.length,
          totalPendingAssignments: pendingAssignments.length,
          totalLateAssignments: lateAssignments.length,
          totalCompletedQuizzes: completedQuizzes.length,
        };

        return {
          role: 'student',
          user: {
            id: user.id,
            full_name: user.full_name,
            avatar_url: user.avatar_url,
          },
          overview,
          submittedAssignments,
          pendingAssignments,
          lateAssignments,
          completedQuizzes,
          upcomingDeadlines,
        };
      }

      // =================================================================
      // ======================= 3️⃣ INSTRUCTOR ===========================
      // =================================================================
      if (isInstructor) {
        // Courses giảng dạy
        const courses = await this.prisma.courses.findMany({
          where: { instructor_id: user_id },
          include: {
            semesters: true,
            groups: {
              include: { student_groups: true },
            },
          },
          orderBy: { created_at: 'desc' },
        });

        const courseIds = courses.map((c) => c.id);

        // Recent
        const recentAnnouncements = await this.prisma.announcements.findMany({
          where: { course_id: { in: courseIds } },
          orderBy: { created_at: 'desc' },
          take: 5,
        });

        const recentMaterials = await this.prisma.materials.findMany({
          where: { course_id: { in: courseIds } },
          orderBy: { created_at: 'desc' },
          take: 5,
        });

        const recentAssignments = await this.prisma.assignments.findMany({
          where: { course_id: { in: courseIds } },
          orderBy: { created_at: 'desc' },
          take: 5,
        });

        const recentQuizzes = await this.prisma.quizzes.findMany({
          where: { course_id: { in: courseIds } },
          orderBy: { created_at: 'desc' },
          take: 5,
        });

        // Work requiring review (bài đã nộp chưa chấm)
        const submissionsToReview = await this.prisma.submissions.findMany({
          where: {
            assignment_id: { in: courseIds },
            grade: null,
          },
          take: 5,
          orderBy: { submitted_at: 'desc' },
        });

        // Quiz attempts mới
        const recentQuizAttempts = await this.prisma.quiz_attempts.findMany({
          where: { quiz_id: { in: courseIds } },
          include: { students: true },
          orderBy: { submitted_at: 'desc' },
          take: 5,
        });

        // Summary
        const overview = {
          totalCourses: courses.length,
          totalStudents: courses.reduce(
            (sum, c) =>
              sum + c.groups.reduce((s, g) => s + g.student_groups.length, 0),
            0,
          ),
          pendingReviews: submissionsToReview.length,
        };

        return {
          role: 'instructor',
          user: {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            avatar_url: user.avatar_url,
          },

          overview,
          courses,

          recent: {
            announcements: recentAnnouncements,
            materials: recentMaterials,
            assignments: recentAssignments,
            quizzes: recentQuizzes,
          },

          work: {
            submissionsToReview,
            recentQuizAttempts,
          },
        };
      }
    } catch (err) {
      throw new RpcException({
        statusCode: err.statusCode || 500,
        message: err.message || 'Lỗi server getDashboard',
      });
    }
  }
}
