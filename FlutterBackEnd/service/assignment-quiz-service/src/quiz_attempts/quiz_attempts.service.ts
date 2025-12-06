import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import {
  assertFound,
  assertOrBadRequest,
  mapPrismaError,
} from 'src/common/utils/prisma-error.util';
import { CreateQuizAttemptDto } from './dto/create-quiz_attempt.dto';
import { SubmitQuizAttemptDto } from './dto/submit-quiz-attempt.dto';

@Injectable()
export class QuizAttemptsService {
  constructor(private readonly prisma: PrismaService) {}

  // ========================== START QUIZ ==========================
  // ========================== START QUIZ ==========================
  async startAttempt(userId: number, dto: CreateQuizAttemptDto) {
    try {
      console.log(dto.quiz_id);
      const quiz = await this.prisma.quizzes.findFirst({
        where: { id: dto.quiz_id },
      });
      assertFound(quiz, 'Quiz không tồn tại');

      const student = await this.prisma.students.findFirst({
        where: { user_id: userId },
      });
      assertFound(student, 'Sinh viên không tồn tại');
      console.log(quiz.id);
      console.log(quiz.open_time);
      console.log(quiz.close_time);
      // Check time
      const now = new Date();
      const openTime = new Date(quiz.open_time.toISOString());
      const closeTime = new Date(quiz.close_time.toISOString());

      if (now < openTime) this.bad(400, 'Quiz chưa mở');
      if (now > closeTime) this.bad(400, 'Quiz đã đóng');
      if (quiz.open_time && now < quiz.open_time) this.bad(400, 'Quiz chưa mở');
      if (quiz.close_time && now > quiz.close_time)
        this.bad(400, 'Quiz đã đóng');

      // Check attempts
      const count = await this.prisma.quiz_attempts.count({
        where: { quiz_id: dto.quiz_id, student_id: student.id },
      });
      if (quiz.max_attempts && count >= quiz.max_attempts)
        this.bad(400, `Bạn đã vượt quá số lần làm (${quiz.max_attempts})`);

      const attempt_no = count + 1;

      // ===== 1. Create attempt =====
      const attempt = await this.prisma.quiz_attempts.create({
        data: {
          quiz_id: dto.quiz_id,
          student_id: student.id,
          attempt_no,
          started_at: now,
        },
      });

      // ===== 2. Random questions =====
      const questionsEasy = await this.prisma.quiz_question_bank.findMany({
        where: { course_id: quiz.course_id, difficulty: 'easy' },
        orderBy: { id: 'asc' },
        take: quiz.random_easy ?? 0,
      });

      const questionsMedium = await this.prisma.quiz_question_bank.findMany({
        where: { course_id: quiz.course_id, difficulty: 'medium' },
        orderBy: { id: 'asc' },
        take: quiz.random_medium ?? 0,
      });

      const questionsHard = await this.prisma.quiz_question_bank.findMany({
        where: { course_id: quiz.course_id, difficulty: 'hard' },
        orderBy: { id: 'asc' },
        take: quiz.random_hard ?? 0,
      });

      const allQuestions = [
        ...questionsEasy,
        ...questionsMedium,
        ...questionsHard,
      ];

      // Shuffle
      allQuestions.sort(() => Math.random() - 0.5);

      // ===== 3. Insert quiz_attempt_questions =====
      await this.prisma.quiz_attempt_questions.createMany({
        data: allQuestions.map((q, index) => ({
          quiz_attempt_id: attempt.id,
          question_id: q.id,
          order_index: index + 1,
        })),
      });

      // ===== 4. Return attempt + questions =====
      return {
        message: 'Bắt đầu quiz thành công',
        attempt_id: attempt.id,
        questions: allQuestions.map((q, i) => ({
          id: q.id,
          text: q.question_text,
          a: q.option_a,
          b: q.option_b,
          c: q.option_c,
          d: q.option_d,
          order: i + 1,
        })),
      };
    } catch (err) {
      mapPrismaError(err, 'quiz_attempts.startAttempt');
    }
  }

  // ========================== SUBMIT QUIZ ==========================
  // ========================== SUBMIT QUIZ ==========================
  async submit(dto: SubmitQuizAttemptDto) {
    try {
      // 1. Verify attempt
      const attempt = await this.prisma.quiz_attempts.findFirst({
        where: { id: dto.attempt_id },
        include: { quizzes: true },
      });
      assertFound(attempt, 'Lần làm không tồn tại');

      // Check close time
      const now = new Date();
      if (attempt.quizzes.close_time && now > attempt.quizzes.close_time)
        this.bad(400, 'Quiz đã đóng, không thể nộp');

      // 2. Lấy toàn bộ câu hỏi đã được random khi START
      const attemptQuestions =
        await this.prisma.quiz_attempt_questions.findMany({
          where: { quiz_attempt_id: dto.attempt_id },
          include: { quiz_question_bank: true },
        });

      // Map theo question_id để tra nhanh
      const questionMap = new Map(
        attemptQuestions.map((q) => [q.question_id, q]),
      );

      let correct = 0;
      const updateOps = [];

      // 3. Xử lý từng câu từ FE gửi lên
      for (const ans of dto.answers) {
        const q = questionMap.get(ans.question_id);
        if (!q) continue; // phòng trường hợp dữ liệu bị sai

        const isCorrect =
          ans.selected_option.toLowerCase() ===
          q.quiz_question_bank.correct_option.toLowerCase();

        if (isCorrect) correct++;

        // Prepare update operation
        updateOps.push(
          this.prisma.quiz_attempt_questions.update({
            where: { id: q.id },
            data: {
              selected_option: ans.selected_option,
              is_correct: isCorrect,
            },
          }),
        );
      }

      // Chạy update đồng thời
      await Promise.all(updateOps);

      // 4. Tính điểm (thang 10)
      const total = attemptQuestions.length;
      const score = total > 0 ? (correct / total) * 10 : 0;

      // 5. Update bảng quiz_attempts
      const updatedAttempt = await this.prisma.quiz_attempts.update({
        where: { id: dto.attempt_id },
        data: {
          score,
          submitted_at: now,
        },
      });

      console.log(score);
      console.log(correct);
      console.log(total);
      console.log(updatedAttempt);
      return {
        message: 'Nộp quiz thành công',
        score,
        correct,
        total,
        data: updatedAttempt,
      };
    } catch (err) {
      mapPrismaError(err, 'quiz_attempts.submit');
    }
  }

  // ========================== GET BY QUIZ ==========================
  async getByQuiz(quizId: number) {
    try {
      const quiz = await this.prisma.quizzes.findFirst({
        where: { id: quizId },
      });
      assertFound(quiz, 'Quiz không tồn tại');

      const data = await this.prisma.quiz_attempts.findMany({
        where: { quiz_id: quizId },
        include: {
          students: {
            include: { users: { select: { full_name: true, email: true } } },
          },
        },
        orderBy: [{ student_id: 'asc' }, { attempt_no: 'asc' }],
      });

      return { message: 'Lấy danh sách kết quả quiz thành công', data };
    } catch (err) {
      mapPrismaError(err, 'quiz_attempts.getByQuiz');
    }
  }

  private bad(status: number, message: string): never {
    throw { statusCode: status, message };
  }
}
