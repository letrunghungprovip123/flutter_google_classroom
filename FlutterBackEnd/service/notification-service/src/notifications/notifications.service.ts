import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { UpdateNotificationDto } from './dto/update-notification.dto';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

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

  // 🔹 Tạo thông báo
  async create(dto: CreateNotificationDto) {
    try {
      const student = await this.prisma.students.findFirst({
        where: { id: dto.student_id },
      });
      if (!student) this.bad(404, 'Sinh viên không tồn tại');

      const created = await this.prisma.notifications.create({ data: dto });
      return { message: 'Tạo thông báo thành công', data: created };
    } catch (err) {
      this.rethrow(err, 'notifications.create');
    }
  }

  // 🔹 Lấy danh sách thông báo theo student_id
  async getByStudent(student_id: number) {
    try {
      const student = await this.prisma.students.findFirst({
        where: { user_id: student_id },
      });
      if (!student) this.bad(404, 'Sinh viên không tồn tại');

      const data = await this.prisma.notifications.findMany({
        where: { student_id: student.id },
        orderBy: { created_at: 'desc' },
      });

      return { message: 'Lấy danh sách thông báo thành công', data };
    } catch (err) {
      this.rethrow(err, 'notifications.getByStudent');
    }
  }

  // 🔹 Đánh dấu đã đọc
  async markAsRead(id: number) {
    try {
      const existed = await this.prisma.notifications.findFirst({
        where: { id },
      });
      if (!existed) this.bad(404, 'Thông báo không tồn tại');

      const updated = await this.prisma.notifications.update({
        where: { id },
        data: { is_read: true },
      });

      return { message: 'Đã đánh dấu thông báo là đã đọc', data: updated };
    } catch (err) {
      this.rethrow(err, 'notifications.markAsRead');
    }
  }
}
