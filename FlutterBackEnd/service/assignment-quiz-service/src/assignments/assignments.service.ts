// assignment-service/src/assignments/assignments.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import {
  AttachmentDto,
  CreateAssignmentDto,
} from './dto/create-assignment.dto';
import { UpdateAssignmentDto } from './dto/update-assignment.dto';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { EmailService } from 'src/email/email.service';

@Injectable()
export class AssignmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
    private readonly emailService: EmailService,
  ) {}

  // Helpers
  private assertOrBadRequest(cond: boolean, message: string): void {
    if (!cond) throw new RpcException({ statusCode: 400, message });
  }
  private async assertFoundById<T>(obj: T | null, message: string) {
    if (!obj) throw new RpcException({ statusCode: 404, message });
  }
  private rethrowRpc(err: any, where: string): never {
    if (err instanceof RpcException) throw err;
    throw new RpcException({
      statusCode: 500,
      message: err?.message || `Lỗi hệ thống tại ${where}`,
    });
  }

  private validateDates(dto: {
    start_date?: string;
    deadline?: string;
    late_deadline?: string;
    allow_late?: boolean;
  }) {
    const { start_date, deadline, late_deadline, allow_late } = dto;
    if (start_date && deadline) {
      this.assertOrBadRequest(
        new Date(start_date) <= new Date(deadline),
        'start_date phải ≤ deadline',
      );
    }
    if (late_deadline) {
      this.assertOrBadRequest(
        allow_late === true,
        'late_deadline chỉ hợp lệ khi allow_late = true',
      );
      if (deadline) {
        this.assertOrBadRequest(
          new Date(late_deadline) >= new Date(deadline),
          'late_deadline phải ≥ deadline',
        );
      }
    }
  }

  async list(filter: { courseId?: number }) {
    try {
      if (filter?.courseId) {
        const course = await this.prisma.courses.findFirst({
          where: { id: +filter.courseId },
        });
        await this.assertFoundById(course, 'Khoá học không tồn tại');
      }

      const data = await this.prisma.assignments.findMany({
        where: filter?.courseId ? { course_id: +filter.courseId } : undefined,
        orderBy: { id: 'asc' },
        include: {
          attachments: true,
        },
      });
      return { message: 'Lấy danh sách bài tập thành công', data };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.list');
    }
  }

  async detail(id: number) {
    try {
      const a = await this.prisma.assignments.findFirst({
        where: { id },
        include: {
          courses: { select: { id: true, name: true, code: true } },
          users: { select: { id: true, full_name: true, email: true } },
          attachments: true,
        },
      });
      await this.assertFoundById(a, 'Bài tập không tồn tại');
      return { message: 'Lấy chi tiết bài tập thành công', data: a };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.detail');
    }
  }

  async create(dto: CreateAssignmentDto, attachments: AttachmentDto[]) {
    try {
      // -----------------------------
      // Validate course + instructor
      // -----------------------------
      const course = await this.prisma.courses.findFirst({
        where: { id: dto.course_id },
      });
      await this.assertFoundById(course, 'Khoá học không tồn tại');

      const instructor = await this.prisma.users.findFirst({
        where: { id: dto.instructor_id },
      });
      await this.assertFoundById(instructor, 'Giảng viên không tồn tại');

      // Validate start/deadline/late logic
      this.validateDates(dto);

      // -----------------------------
      // Create Assignment
      // -----------------------------
      const created = await this.prisma.assignments.create({
        data: {
          title: dto.title,
          description: dto.description ?? null,
          start_date: dto.start_date ? new Date(dto.start_date) : null,
          deadline: dto.deadline ? new Date(dto.deadline) : null,
          late_deadline: dto.late_deadline ? new Date(dto.late_deadline) : null,
          allow_late: dto.allow_late ?? false,
          max_attempts: dto.max_attempts ?? 1,
          file_format: dto.file_format ?? null,
          file_size_limit_mb: dto.file_size_limit_mb ?? 10,
          courses: { connect: { id: dto.course_id } },
          users: { connect: { id: dto.instructor_id } },
        },
      });

      // -----------------------------
      // Upload attachments
      // -----------------------------
      for (const file of attachments) {
        const buffer = Buffer.from(file.buffer, 'base64');

        const uploaded = await this.cloudinary.uploadBuffer(
          buffer,
          file.originalname,
          file.mimetype,
          'assignments', // 🔥 folder dynamic
        );

        await this.prisma.assignment_attachments.create({
          data: {
            assignment_id: created.id,
            file_url: uploaded.secure_url,
            file_name: file.originalname,
            file_type: uploaded.format,
            file_size: uploaded.bytes,
          },
        });
      }

      // 🔥 Lấy danh sách tất cả sinh viên của khoá học
      const students = await this.prisma.student_groups.findMany({
        where: {
          groups: {
            course_id: dto.course_id,
          },
        },
        select: {
          students: {
            select: { users: { select: { email: true, full_name: true } } },
          },
          student_id: true,
        },
      });

      // Gửi email đến từng sinh viên
      if (students.length > 0) {
        for (const s of students) {
          // 🔹 Notification Database
          await this.prisma.notifications.create({
            data: {
              student_id: s.student_id,
              title: 'Bài tập mới',
              message: `Bài tập mới: ${created.title}`,
            },
          });

          // 🔹 Email
          const email = s.students.users.email;
          if (!email) continue;

          await this.emailService.sendAssignmentReminder(
            email,
            course.name,
            created.title,
            created.deadline
              ? new Date(created.deadline).toLocaleString('vi-VN')
              : 'Không có hạn',
          );
        }
      }

      // -----------------------------
      // Return full assignment
      // -----------------------------
      const full = await this.prisma.assignments.findFirst({
        where: { id: created.id },
        include: { submissions: true, attachments: true },
      });

      return { message: 'Tạo bài tập thành công', data: full };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.create');
    }
  }

  async update(
    id: number,
    dto: UpdateAssignmentDto,
    attachments: AttachmentDto[],
  ) {
    try {
      const current = await this.prisma.assignments.findFirst({
        where: { id },
      });
      await this.assertFoundById(current, 'Bài tập không tồn tại');

      if (dto.course_id) {
        const course = await this.prisma.courses.findFirst({
          where: { id: dto.course_id },
        });
        await this.assertFoundById(course, 'Khoá học không tồn tại');
      }

      if (dto.instructor_id) {
        const inst = await this.prisma.users.findFirst({
          where: { id: dto.instructor_id },
        });
        await this.assertFoundById(inst, 'Giảng viên không tồn tại');
      }

      this.validateDates(dto);

      // -----------------------------
      // Update assignment info
      // -----------------------------
      await this.prisma.assignments.update({
        where: { id },
        data: {
          title: dto.title ?? current.title,
          description: dto.description ?? current.description,
          start_date: dto.start_date
            ? new Date(dto.start_date)
            : current.start_date,
          deadline: dto.deadline ? new Date(dto.deadline) : current.deadline,
          late_deadline: dto.late_deadline
            ? new Date(dto.late_deadline)
            : current.late_deadline,

          // ✔ FIX allow_late
          allow_late:
            typeof dto.allow_late === 'boolean'
              ? dto.allow_late
              : current.allow_late,

          max_attempts: dto.max_attempts ?? current.max_attempts,
          file_format: dto.file_format ?? current.file_format,
          file_size_limit_mb:
            dto.file_size_limit_mb ?? current.file_size_limit_mb,

          ...(dto.course_id
            ? { courses: { connect: { id: dto.course_id } } }
            : {}),

          ...(dto.instructor_id
            ? { users: { connect: { id: dto.instructor_id } } }
            : {}),
        },
      });

      // -----------------------------
      // Upload new attachments
      // -----------------------------
      for (const file of attachments) {
        const buffer = Buffer.from(file.buffer, 'base64');

        const uploaded = await this.cloudinary.uploadBuffer(
          buffer,
          file.originalname,
          file.mimetype,
          'assignments',
        );

        await this.prisma.assignment_attachments.create({
          data: {
            assignment_id: id,
            file_url: uploaded.secure_url,
            file_name: uploaded.original_filename,
            file_type: uploaded.format,
            file_size: uploaded.bytes,
          },
        });
      }

      const full = await this.prisma.assignments.findFirst({
        where: { id },
        include: {
          submissions: true,
          attachments: true,
        },
      });

      return { message: 'Cập nhật bài tập thành công', data: full };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.update');
    }
  }

  async delete(id: number) {
    try {
      const current = await this.prisma.assignments.findFirst({
        where: { id },
      });
      await this.assertFoundById(current, 'Bài tập không tồn tại');

      // Xoá submissions liên quan (nếu cần; FK onDelete=Cascade thì không cần)
      await this.prisma.submissions.deleteMany({
        where: { assignment_id: id },
      });

      await this.prisma.assignments.delete({ where: { id } });
      return { message: 'Xoá bài tập thành công' };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.delete');
    }
  }

  async summary(id: number) {
    try {
      const a = await this.prisma.assignments.findFirst({ where: { id } });
      await this.assertFoundById(a, 'Bài tập không tồn tại');

      const all = await this.prisma.submissions.findMany({
        where: { assignment_id: id },
        select: { id: true, submitted_at: true },
      });

      const deadline = a.deadline ? new Date(a.deadline) : null;
      let ontime = 0,
        late = 0;

      if (deadline) {
        for (const s of all) {
          if (!s.submitted_at) continue;
          if (new Date(s.submitted_at) <= deadline) ontime++;
          else late++;
        }
      } else {
        // Không có deadline -> mọi submission coi như "ontime"
        ontime = all.length;
      }

      return {
        message: 'Tổng hợp nộp bài',
        data: {
          assignment_id: id,
          total_submissions: all.length,
          ontime,
          late,
        },
      };
    } catch (err) {
      this.rethrowRpc(err, 'assignments.summary');
    }
  }
}
