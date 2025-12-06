import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import {
  assertFound,
  assertOrBadRequest,
  mapPrismaError,
} from 'src/common/utils/prisma-error.util';
import { CreateQuestionBankDto, CreateQuizDto } from './dto/create-quiz.dto';
import { UpdateQuizDto } from './dto/update-quiz.dto';
import { AiService } from 'src/ai/ai.service';

@Injectable()
export class QuizzesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ai: AiService,
  ) {}

  // GET_ALL
  async getAll(filter: { courseId?: number }) {
    try {
      const where = filter.courseId ? { course_id: +filter.courseId } : {};
      const data = await this.prisma.quizzes.findMany({
        where,
        include: {
          courses: { select: { name: true } },
          users: { select: { full_name: true } },
        },
        orderBy: { id: 'asc' },
      });
      return { message: 'Lấy danh sách quiz thành công', data };
    } catch (err) {
      mapPrismaError(err, 'quizzes.getAll');
    }
  }

  async generateAi(body: any) {
    try {
      const result = await this.ai.generateSuggestion(body); // gọi service Gemini
      let raw = result;

      if (typeof raw !== 'string') {
        throw new Error('Invalid raw AI format (not string)');
      }

      // 🔥 Strip ```json ... ```
      raw = raw
        .trim()
        .replace(/^```json/i, '')
        .replace(/^```/, '')
        .replace(/```$/, '');

      return raw;
    } catch (error) {
      return error;
    }
  }
  // GET_BY_ID
  async getById(id: number) {
    try {
      const quiz = await this.prisma.quizzes.findFirst({
        where: { id },
        include: {
          // Thông tin course nếu cần

          // Tất cả attempt của quiz này
          quiz_attempts: {
            include: {
              // Lấy student tương ứng với attempt
              students: {
                include: {
                  // Và user của student đó để hiển thị full_name, email, avatar...
                  users: true,
                },
              },
            },
            orderBy: [
              { submitted_at: 'desc' }, // mới nhất lên đầu, thích thì đổi 'asc'
              { attempt_no: 'asc' },
            ],
          },
        },
      });

      assertFound(quiz, 'Quiz không tồn tại');

      // Tính tổng số student đã làm bài (distinct student_id)
      const distinctStudentIds = new Set(
        quiz.quiz_attempts
          .filter((a) => a.student_id !== null)
          .map((a) => a.student_id as number),
      );

      const totalStudentsAttempted = distinctStudentIds.size;
      const totalAttempts = quiz.quiz_attempts.length;

      return {
        message: 'Lấy chi tiết quiz thành công',
        data: {
          ...quiz,
          stats: {
            totalStudentsAttempted,
            totalAttempts,
          },
        },
      };
    } catch (err) {
      mapPrismaError(err, 'quizzes.getById');
    }
  }

  // CREATE QUIZ
  async create(dto: CreateQuizDto) {
    try {
      const course = await this.prisma.courses.findFirst({
        where: { id: dto.course_id },
      });
      assertFound(course, 'Khoá học không tồn tại');

      // const instructor = await this.prisma.users.findFirst({
      //   where: { id: dto.instructor_id, role: 'instructor' },
      // });
      // assertFound(instructor, 'Giảng viên không tồn tại');

      // ===========================
      // 🔥 VALIDATE QUESTION COUNTS
      // ===========================
      const questionCounts = await this.prisma.quiz_question_bank.groupBy({
        by: ['difficulty'],
        where: { course_id: dto.course_id },
        _count: { id: true },
      });

      const countEasy =
        questionCounts.find((q) => q.difficulty === 'easy')?._count.id || 0;
      const countMedium =
        questionCounts.find((q) => q.difficulty === 'medium')?._count.id || 0;
      const countHard =
        questionCounts.find((q) => q.difficulty === 'hard')?._count.id || 0;

      assertOrBadRequest(
        (dto.random_easy ?? 0) <= countEasy,
        `Không đủ câu hỏi mức dễ (hiện có ${countEasy}, yêu cầu ${dto.random_easy})`,
      );

      assertOrBadRequest(
        (dto.random_medium ?? 0) <= countMedium,
        `Không đủ câu hỏi mức trung bình (hiện có ${countMedium}, yêu cầu ${dto.random_medium})`,
      );

      assertOrBadRequest(
        (dto.random_hard ?? 0) <= countHard,
        `Không đủ câu hỏi mức khó (hiện có ${countHard}, yêu cầu ${dto.random_hard})`,
      );

      // 1️⃣ Tạo quiz
      const created = await this.prisma.quizzes.create({
        data: {
          course_id: dto.course_id,
          instructor_id: 2,
          title: dto.title,
          open_time: dto.open_time ? new Date(dto.open_time) : null,
          close_time: dto.close_time ? new Date(dto.close_time) : null,
          duration_minutes: dto.duration_minutes ?? null,
          max_attempts: dto.max_attempts ?? 1,
          random_easy: dto.random_easy ?? 0,
          random_medium: dto.random_medium ?? 0,
          random_hard: dto.random_hard ?? 0,
        },
      });

      // 2️⃣ Lấy danh sách students thuộc course
      const students = await this.prisma.student_groups.findMany({
        where: { groups: { course_id: dto.course_id } },
        select: { student_id: true },
      });

      // 3️⃣ Tạo notification cho tất cả student
      if (students.length > 0) {
        await this.prisma.notifications.createMany({
          data: students.map((s) => ({
            student_id: s.student_id,
            title: 'Quiz mới',
            message: `Bạn có quiz mới: ${dto.title}`,
          })),
        });
      }

      return {
        message: 'Tạo quiz thành công',
        data: created,
      };
    } catch (err) {
      mapPrismaError(err, 'quizzes.create');
    }
  }

  // UPDATE
  async update(id: number, dto: UpdateQuizDto) {
    try {
      const quiz = await this.prisma.quizzes.findFirst({ where: { id } });
      assertFound(quiz, 'Quiz không tồn tại');

      const updated = await this.prisma.quizzes.update({
        where: { id },
        data: {
          ...dto,
          open_time: dto.open_time ? new Date(dto.open_time) : quiz.open_time,
          close_time: dto.close_time
            ? new Date(dto.close_time)
            : quiz.close_time,
        },
      });
      return { message: 'Cập nhật quiz thành công', data: updated };
    } catch (err) {
      mapPrismaError(err, 'quizzes.update');
    }
  }

  // DELETE
  async delete(id: number) {
    try {
      const quiz = await this.prisma.quizzes.findFirst({ where: { id } });
      assertFound(quiz, 'Quiz không tồn tại');

      await this.prisma.quizzes.delete({ where: { id } });
      return { message: 'Xoá quiz thành công' };
    } catch (err) {
      mapPrismaError(err, 'quizzes.delete');
    }
  }
  async createQuestion(dtos: CreateQuestionBankDto[]) {
    try {
      await this.prisma.quiz_question_bank.createMany({
        data: dtos,
        skipDuplicates: true,
      });

      // 👉 Lấy lại dữ liệu vừa tạo từ question_text để trả về FE
      const texts = dtos.map((q) => q.question_text);

      const data = await this.prisma.quiz_question_bank.findMany({
        where: { question_text: { in: texts } },
      });

      return {
        message: `Thêm ${data.length} câu hỏi thành công`,
        count: data.length,
        data, // FE có id ngay để update UI
      };
    } catch (err) {
      mapPrismaError(err, 'questionbank.createMany');
    }
  }

  async deleteQuestion(id: number) {
    try {
      await this.prisma.quiz_question_bank.delete({ where: { id } });
      return { message: 'Xóa câu hỏi thành công' };
    } catch (err) {
      mapPrismaError(err, 'questionbank.delete');
    }
  }

  async getAllQuestions(course_id: number) {
    try {
      const data = await this.prisma.quiz_question_bank.findMany({
        where: { course_id },
        orderBy: { id: 'asc' },
      });
      return { message: 'Lấy danh sách câu hỏi thành công', data };
    } catch (err) {
      mapPrismaError(err, 'questionbank.getAllByCourse');
    }
  }

  async getQuestionById(id: number) {
    try {
      const data = await this.prisma.quiz_question_bank.findUnique({
        where: { id },
      });
      assertFound(data, 'Câu hỏi không tồn tại');
      return { message: 'Lấy chi tiết câu hỏi thành công', data };
    } catch (err) {
      mapPrismaError(err, 'questionbank.getById');
    }
  }
}
