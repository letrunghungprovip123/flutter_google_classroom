import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import { AttachmentDto, CreateMaterialDto } from './dto/create-material.dto';
import { UpdateMaterialDto } from './dto/update-material.dto';
import {
  assertFound,
  assertOrBadRequest,
  mapPrismaError,
} from 'src/common/utils/prisma-error.util';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';

@Injectable()
export class MaterialsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  private bad(statusCode: number, message: string): never {
    throw new RpcException({ statusCode, message });
  }
  private rethrow(err: any, where: string): never {
    if (err instanceof RpcException) throw err;
    console.error(`[Error:${where}]`, err);
    throw new RpcException({
      statusCode: err?.statusCode || 500,
      message: err?.message || `Lỗi server tại ${where}`,
    });
  }

  // GET /materials?courseId=
  async getByCourse(filter: { courseId?: number }) {
    try {
      if (filter?.courseId) {
        const course = await this.prisma.courses.findFirst({
          where: { id: +filter.courseId },
        });
        assertFound(course, 'Khoá học không tồn tại');
      }

      const data = await this.prisma.materials.findMany({
        where: filter?.courseId ? { course_id: +filter.courseId } : {},
        orderBy: { id: 'asc' },
        include: {
          attachments: true,
        },
      });
      return { message: 'Lấy danh sách tài liệu thành công', data };
    } catch (err) {
      mapPrismaError(err, 'materials.getByCourse');
    }
  }

  // GET /materials/:id
  async getById(id: number) {
    try {
      const mat = await this.prisma.materials.findFirst({
        where: { id },
        include: { attachments: true },
      });
      assertFound(mat, 'Tài liệu không tồn tại');
      return { message: 'Lấy chi tiết tài liệu thành công', data: mat };
    } catch (err) {
      mapPrismaError(err, 'materials.getById');
    }
  }

  // POST /materials
  async create(dto: CreateMaterialDto, attachments: AttachmentDto[]) {
    try {
      // 1️⃣ Kiểm tra course
      const course = await this.prisma.courses.findFirst({
        where: { id: dto.course_id },
      });
      assertFound(course, 'Khoá học không tồn tại');

      // 2️⃣ Kiểm tra instructor
      const instructor = await this.prisma.users.findFirst({
        where: { id: dto.instructor_id },
      });
      assertFound(instructor, 'Giảng viên không tồn tại');

      assertOrBadRequest(
        dto.title?.trim().length > 0,
        'Thiếu tiêu đề tài liệu',
      );

      // 3️⃣ Tạo material
      const material = await this.prisma.materials.create({
        data: {
          course_id: dto.course_id,
          instructor_id: dto.instructor_id,
          title: dto.title.trim(),
          description: dto.description ?? null,
        },
      });

      // 4️⃣ Upload files → lưu material_attachments
      for (const file of attachments) {
        const buffer = Buffer.from(file.buffer, 'base64');

        const uploaded = await this.cloudinary.uploadFile(
          buffer,
          file.originalname,
          file.mimetype,
        );

        await this.prisma.material_attachments.create({
          data: {
            material_id: material.id,
            file_url: uploaded.secure_url,
            file_name: file.originalname,
            file_type: uploaded.format,
            file_size: uploaded.bytes,
          },
        });
      }

      // 5️⃣ Lấy toàn bộ student thuộc course
      const students = await this.prisma.student_groups.findMany({
        where: {
          groups: {
            course_id: dto.course_id,
          },
        },
        select: { student_id: true },
      });

      // 6️⃣ Tự động tạo NOTIFICATION cho từng student
      if (students.length > 0) {
        await this.prisma.notifications.createMany({
          data: students.map((s) => ({
            student_id: s.student_id,
            title: 'Tài liệu mới',
            message: `Khoá học có tài liệu mới: ${material.title}`,
          })),
        });
      }

      // 7️⃣ Lấy material + attachments và trả về
      const fullMaterial = await this.prisma.materials.findFirst({
        where: { id: material.id },
        include: {
          attachments: true,
        },
      });

      return {
        message: 'Tạo tài liệu thành công',
        data: fullMaterial,
      };
    } catch (err) {
      mapPrismaError(err, 'materials.create');
    }
  }

  // PATCH /materials/:id
  async update(id: number, dto: UpdateMaterialDto) {
    try {
      const existed = await this.prisma.materials.findFirst({ where: { id } });
      assertFound(existed, 'Tài liệu không tồn tại');

      const updated = await this.prisma.materials.update({
        where: { id },
        data: {
          title: dto.title ?? existed.title,
          description: dto.description ?? existed.description,
          file_url: dto.file_url ?? existed.file_url,
        },
      });
      return { message: 'Cập nhật tài liệu thành công', data: updated };
    } catch (err) {
      mapPrismaError(err, 'materials.update');
    }
  }

  // DELETE /materials/:id
  async delete(id: number) {
    try {
      const existed = await this.prisma.materials.findFirst({ where: { id } });
      assertFound(existed, 'Tài liệu không tồn tại');

      await this.prisma.materials.delete({ where: { id } });
      return { message: 'Xoá tài liệu thành công' };
    } catch (err) {
      mapPrismaError(err, 'materials.delete');
    }
  }

  // GET /materials/:id/view  (optional: mock tracking — chưa có bảng)
  async trackView(id: number, payload: { student_id?: number }) {
    try {
      const existed = await this.prisma.materials.findFirst({ where: { id } });
      assertFound(existed, 'Tài liệu không tồn tại');

      // Chưa có bảng view -> trả lời “đã ghi nhận”
      return {
        message:
          'Đã ghi nhận lượt xem (mock). Có thể thêm bảng material_views sau.',
        data: { material_id: id, viewer: payload?.student_id ?? null },
      };
    } catch (err) {
      mapPrismaError(err, 'materials.trackView');
    }
  }
}
