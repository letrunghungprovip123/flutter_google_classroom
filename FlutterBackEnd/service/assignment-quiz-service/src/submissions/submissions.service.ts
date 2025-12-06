import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import {
  AttachmentDto,
  CreateSubmissionDto,
} from './dto/create-submission.dto';
import { GradeSubmissionDto } from './dto/grade-submission.dto';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';

@Injectable()
export class SubmissionsService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
  ) {}

  private bad(status: number, msg: string) {
    throw new RpcException({ statusCode: status, message: msg });
  }
  private rethrow(err: any, where: string): never {
    if (err instanceof RpcException) throw err;
    throw new RpcException({
      statusCode: 500,
      message: err?.message || `Lỗi hệ thống tại ${where}`,
    });
  }

  async create(dto: CreateSubmissionDto, attachments: AttachmentDto[]) {
    try {
      // ===== Validate bài tập =====
      const assignment = await this.prisma.assignments.findFirst({
        where: { id: dto.assignment_id },
      });
      if (!assignment) this.bad(404, 'Bài tập không tồn tại');

      // ===== Tìm sinh viên bằng user_id =====
      const student = await this.prisma.students.findFirst({
        where: { user_id: dto.student_id },
      });
      if (!student) this.bad(404, 'Sinh viên không tồn tại');

      // Replace student_id → student table id
      const studentId = student.id;

      // ===== Lấy số lần nộp =====
      const currentAttempts = await this.prisma.submissions.count({
        where: {
          assignment_id: dto.assignment_id,
          student_id: studentId,
        },
      });

      const nextAttempt = currentAttempts + 1;
      const maxAttempts = assignment.max_attempts ?? 1;

      if (nextAttempt > maxAttempts) {
        this.bad(400, `Bạn đã vượt quá số lần nộp (${maxAttempts})`);
      }

      // ===== Kiểm tra hạn nộp =====
      const now = new Date();
      let status: 'on_time' | 'late' = 'on_time';

      const deadline = assignment.deadline
        ? new Date(assignment.deadline)
        : null;
      const lateDeadline = assignment.late_deadline
        ? new Date(assignment.late_deadline)
        : null;

      if (deadline && now > deadline) {
        if (!assignment.allow_late) {
          this.bad(400, 'Đã quá hạn nộp bài (không cho phép nộp trễ)');
        }
        if (lateDeadline && now > lateDeadline) {
          this.bad(400, 'Đã quá hạn nộp bài trễ');
        }
        status = 'late';
      }

      // ===== Tạo submission =====
      const created = await this.prisma.submissions.create({
        data: {
          assignments: { connect: { id: dto.assignment_id } },
          students: { connect: { id: studentId } },
          attempt_no: nextAttempt,
          submitted_at: now,
          status,
          file_url: dto.file_url ?? null,
        },
      });

      // ===== Upload nhiều file (attachments) =====
      for (const f of attachments) {
        const buffer = Buffer.from(f.buffer, 'base64');

        const uploaded = await this.cloudinary.uploadBuffer(
          buffer,
          f.originalname,
          f.mimetype,
          'submissions', // 🔥 folder dynamic
        );

        await this.prisma.submission_attachments.create({
          data: {
            submission_id: created.id,
            file_url: uploaded.secure_url,
            file_name: f.originalname,
            file_type: uploaded.format,
            file_size: uploaded.bytes,
          },
        });
      }

      const full = await this.prisma.submissions.findFirst({
        where: { id: created.id },
        include: {
          attachments: true,
          assignments: true,
          students: true,
        },
      });

      return {
        message: `Nộp bài thành công (Lần ${nextAttempt}/${maxAttempts})`,
        data: full,
      };
    } catch (err) {
      this.rethrow(err, 'submissions.create');
    }
  }

  async listByAssignment(assignmentId: number) {
    try {
      const a = await this.prisma.assignments.findFirst({
        where: { id: assignmentId },
      });
      if (!a) this.bad(404, 'Bài tập không tồn tại');

      const data = await this.prisma.submissions.findMany({
        where: { assignment_id: assignmentId },
        include: {
          students: {
            include: {
              users: true,
            },
          },
          attachments: true,
        },
        orderBy: [{ attempt_no: 'asc' }, { submitted_at: 'asc' }],
      });

      return { message: 'Lấy danh sách bài nộp thành công', data };
    } catch (err) {
      this.rethrow(err, 'submissions.listByAssignment');
    }
  }

  async getMySubmission(payload: { assignmentId: number; userId: number }) {
    const { assignmentId, userId } = payload;

    const student = await this.prisma.students.findFirst({
      where: { user_id: userId },
    });

    if (!student) this.bad(404, 'Không tìm thấy student');

    const latest = await this.prisma.submissions.findFirst({
      where: {
        assignment_id: assignmentId,
        student_id: student.id,
      },
      orderBy: { attempt_no: 'desc' },
      include: { attachments: true },
    });

    return {
      message: 'Lấy bài nộp mới nhất thành công',
      data: latest,
    };
  }

  async grade(dto: GradeSubmissionDto) {
    try {
      const s = await this.prisma.submissions.findFirst({
        where: { id: dto.submission_id },
      });
      if (!s) this.bad(404, 'Bài nộp không tồn tại');

      const updated = await this.prisma.submissions.update({
        where: { id: dto.submission_id },
        data: { grade: dto.grade, status: 'on_time' },
      });

      return { message: 'Chấm điểm thành công', data: updated };
    } catch (err) {
      this.rethrow(err, 'submissions.grade');
    }
  }
}
