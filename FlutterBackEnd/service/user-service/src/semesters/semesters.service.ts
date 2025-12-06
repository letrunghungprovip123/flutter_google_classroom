import { Injectable } from '@nestjs/common';
import { RpcException } from '@nestjs/microservices';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateSemesterDto } from './dto/create-semester.dto';
import { UpdateSemesterDto } from './dto/update-semester.dto';

@Injectable()
export class SemestersService {
  constructor(private prisma: PrismaService) {}

  async list() {
    try {
      const data = await this.prisma.semesters.findMany({
        orderBy: { id: 'desc' },
      });
      return { message: 'Lấy danh sách học kỳ thành công', data };
    } catch (error) {
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async get(id: number) {
    try {
      const data = await this.prisma.semesters.findFirst({ where: { id } });
      if (!data)
        throw new RpcException({
          statusCode: 404,
          message: 'Học kỳ không tồn tại',
        });
      return { message: 'Lấy học kỳ thành công', data };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async create(dto: CreateSemesterDto) {
    try {
      const existed = await this.prisma.semesters.findFirst({
        where: { code: dto.code },
      });
      if (existed)
        throw new RpcException({
          statusCode: 400,
          message: 'Mã học kỳ đã tồn tại',
        });

      const data = await this.prisma.semesters.create({
        data: {
          code: dto.code,
          name: dto.name,
          start_date: dto.start_date ? new Date(dto.start_date) : null,
          end_date: dto.end_date ? new Date(dto.end_date) : null,
        },
      });
      return { message: 'Tạo học kỳ thành công', data };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async update(id: number, dto: UpdateSemesterDto) {
    try {
      const target = await this.prisma.semesters.findFirst({ where: { id } });
      if (!target)
        throw new RpcException({
          statusCode: 404,
          message: 'Học kỳ không tồn tại',
        });

      const data = await this.prisma.semesters.update({
        where: { id },
        data: {
          ...dto,
          start_date: dto.start_date
            ? new Date(dto.start_date)
            : target.start_date,
          end_date: dto.end_date ? new Date(dto.end_date) : target.end_date,
        },
      });
      return { message: 'Cập nhật học kỳ thành công', data };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async delete(id: number) {
    try {
      const target = await this.prisma.semesters.findFirst({ where: { id } });
      if (!target)
        throw new RpcException({
          statusCode: 404,
          message: 'Học kỳ không tồn tại',
        });

      await this.prisma.semesters.delete({ where: { id } });
      return { message: 'Xoá học kỳ thành công' };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }
}
