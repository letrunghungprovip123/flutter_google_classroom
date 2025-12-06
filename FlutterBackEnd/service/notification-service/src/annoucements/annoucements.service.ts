import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import {
  CreateAnnouncementDto,
  AttachmentDto,
} from './dto/create-annoucement.dto';
import { UpdateAnnoucementDto } from './dto/update-annoucement.dto';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { EmailService } from 'src/email/email.service';

@Injectable()
export class AnnoucementsService {
  constructor(
    private prisma: PrismaService,
    private readonly cloudinaryService: CloudinaryService,
    private readonly email: EmailService,
  ) {}

  private bad(statusCode: number, message: string): never {
    throw new RpcException({ statusCode, message });
  }

  private rethrow(err: any, where: string): never {
    console.error(`[Error:${where}]`, err);
    if (err instanceof RpcException) throw err;
    throw new RpcException({
      statusCode: err.statusCode || 500,
      message: err.message || `Lỗi server tại ${where}`,
    });
  }

  // 🔹 Tạo thông báo mới
  async create(dto: CreateAnnouncementDto, attachments: AttachmentDto[]) {
    try {
      const course = await this.prisma.courses.findFirst({
        where: { id: dto.course_id },
      });
      if (!course) this.bad(404, 'Khoá học không tồn tại');

      const instructor = await this.prisma.users.findFirst({
        where: { id: dto.user_id },
      });
      if (!instructor) this.bad(404, 'Người dùng không tồn tại');

      // 1️⃣ Tạo announcement
      const announcement = await this.prisma.announcements.create({
        data: {
          course_id: dto.course_id,
          instructor_id: dto.user_id,
          title: dto.title,
          content: dto.content,
        },
      });

      // 2️⃣ Upload attachments
      for (const file of attachments) {
        const buffer = Buffer.from(file.buffer, 'base64');

        const uploaded = await this.cloudinaryService.uploadBuffer(
          buffer,
          file.originalname,
          file.mimetype,
        );

        await this.prisma.announcement_attachments.create({
          data: {
            announcement_id: announcement.id,
            file_url: uploaded.secure_url,
            file_name: file.originalname,
            file_type: uploaded.format,
            file_size: uploaded.bytes,
          },
        });
      }

      // 3️⃣ Lấy tất cả student thuộc khoá học
      const students = await this.prisma.student_groups.findMany({
        where: {
          groups: {
            course_id: dto.course_id,
          },
        },
        select: { student_id: true },
      });

      // 4️⃣ Tự động tạo notification cho tất cả student
      // 4️⃣ Tự động tạo notification + gửi email cho tất cả student
      if (students.length > 0) {
        const courseName = course.name;

        for (const s of students) {
          const student = await this.prisma.students.findFirst({
            where: { id: s.student_id },
            include: { users: true },
          });

          const email = student?.users?.email;
          if (!email) continue;

          // Tạo Notification
          await this.prisma.notifications.create({
            data: {
              student_id: s.student_id,
              title: 'Thông báo mới',
              message: `Bạn có thông báo mới: ${dto.title}`,
            },
          });

          // 🔥 Gửi email thông báo
          await this.email.sendAnnouncement(
            email,
            courseName,
            dto.title,
            dto.content,
          );
        }
      }

      // 5️⃣ Lấy announcement + attachments trả về FE
      const fullAnnouncement = await this.prisma.announcements.findFirst({
        where: { id: announcement.id },
        include: {
          attachments: true,
          users: true,
        },
      });

      return {
        message: 'Tạo thông báo thành công',
        data: fullAnnouncement,
      };
    } catch (err) {
      this.rethrow(err, 'announcements.create');
    }
  }

  // 🔹 Lấy danh sách thông báo theo course
  async getByCourse(course_id: number) {
    try {
      const course = await this.prisma.courses.findFirst({
        where: { id: course_id },
      });
      if (!course) this.bad(404, 'Khoá học không tồn tại');

      const data = await this.prisma.announcements.findMany({
        where: { course_id },
        orderBy: { created_at: 'desc' },
        include: {
          attachments: true,
          users: true,
        },
      });

      return { message: 'Lấy danh sách thông báo thành công', data };
    } catch (err) {
      this.rethrow(err, 'announcements.getByCourse');
    }
  }

  // 🔹 Lấy chi tiết thông báo
  async detail(id: number) {
    try {
      const announcement = await this.prisma.announcements.findFirst({
        where: { id },
        include: {
          attachments: true,
        },
      });
      if (!announcement) this.bad(404, 'Thông báo không tồn tại');
      return { message: 'Chi tiết thông báo', data: announcement };
    } catch (err) {
      this.rethrow(err, 'announcements.detail');
    }
  }

  // 🔹 Cập nhật thông báo
  async update(id: number, dto: UpdateAnnoucementDto) {
    try {
      const existed = await this.prisma.announcements.findFirst({
        where: { id },
      });
      if (!existed) this.bad(404, 'Thông báo không tồn tại');

      const updated = await this.prisma.announcements.update({
        where: { id },
        data: dto,
      });
      return { message: 'Cập nhật thông báo thành công', data: updated };
    } catch (err) {
      this.rethrow(err, 'announcements.update');
    }
  }

  // 🔹 Xóa thông báo
  async delete(id: number) {
    try {
      const existed = await this.prisma.announcements.findFirst({
        where: { id },
      });
      if (!existed) this.bad(404, 'Thông báo không tồn tại');

      await this.prisma.announcements.delete({ where: { id } });
      return { message: 'Xoá thông báo thành công' };
    } catch (err) {
      this.rethrow(err, 'announcements.delete');
    }
  }

  // =========================
  // COMMENT FUNCTIONS (FIXED)
  // =========================

  async createComment(dto: {
    announcementId: number;
    userId: number;
    content: string;
  }) {
    try {
      const ann = await this.prisma.announcements.findFirst({
        where: { id: dto.announcementId },
      });
      if (!ann) this.bad(404, 'Announcement không tồn tại');

      const created = await this.prisma.announcement_comments.create({
        data: {
          announcement_id: dto.announcementId,
          user_id: dto.userId,
          content: dto.content,
        },
        include: {
          users: true,
        },
      });

      return { message: 'Đã tạo bình luận', data: created };
    } catch (err) {
      this.rethrow(err, 'comments.createComment');
    }
  }

  async getByAnnouncement(announcementId: number) {
    try {
      const cmtList = await this.prisma.announcement_comments.findMany({
        where: { announcement_id: announcementId },
        include: {
          users: {
            select: {
              id: true,
              full_name: true,
              avatar_url: true,
              role: true,
            },
          },
        },
        orderBy: { created_at: 'asc' },
      });

      return { message: 'Lấy danh sách bình luận thành công', data: cmtList };
    } catch (err) {
      this.rethrow(err, 'comments.getByAnnouncement');
    }
  }

  async deleteComment(commentId: number, userId: number) {
    try {
      const cmt = await this.prisma.announcement_comments.findFirst({
        where: { id: commentId },
        include: {
          users: true,
          announcements: {
            include: {
              users: true, // instructor
            },
          },
        },
      });

      if (!cmt) this.bad(404, 'Comment không tồn tại');

      const isOwner = cmt.user_id === userId;
      const isInstructor = cmt.announcements.instructor_id === userId;

      if (!isOwner && !isInstructor) {
        this.bad(403, 'Bạn không có quyền xoá bình luận này');
      }

      await this.prisma.announcement_comments.delete({
        where: { id: commentId },
      });

      return { message: 'Đã xoá bình luận' };
    } catch (err) {
      this.rethrow(err, 'comments.deleteComment');
    }
  }
}
