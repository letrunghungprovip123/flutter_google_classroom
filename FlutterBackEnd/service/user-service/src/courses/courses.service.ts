import { Injectable } from '@nestjs/common';
import { RpcException } from '@nestjs/microservices';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';

@Injectable()
export class CoursesService {
  constructor(private prisma: PrismaService) {}

  async list(filter?: { semesterId?: number }) {
    try {
      // console.log(filter.semesterId)
      const where = filter?.semesterId
        ? { semester_id: +filter.semesterId }
        : {};
      const courses = await this.prisma.courses.findMany({
        where,
        orderBy: { id: 'desc' },
        include: {
          users: {
            // instructor
            select: { id: true, full_name: true },
          },
          groups: {
            // dùng để đếm số lượng nhóm
            select: { id: true },
          },
        },
      });

      const data = courses.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        instructor: c.users
          ? { id: c.users.id, full_name: c.users.full_name }
          : null,
        groupCount: c.groups.length,
      }));

      return { message: 'Lấy danh sách khóa học thành công', data };
    } catch (error) {
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async studentCourse(userId: number, semesterCode: string) {
    try {
      // 1. Lấy student theo user_id
      const student = await this.prisma.students.findFirst({
        where: { user_id: userId },
      });

      if (!student) {
        throw new RpcException({
          statusCode: 400,
          message: 'Student không tồn tại',
        });
      }

      // 2. Lấy courses theo semesterCode + groups mà student thuộc về
      const courses = await this.prisma.courses.findMany({
        where: {
          semesters: {
            code: semesterCode, // 🎯 lọc theo semester
          },
          groups: {
            some: {
              student_groups: {
                some: { student_id: student.id }, // 🎯 lọc theo student
              },
            },
          },
        },
        include: {
          users: { select: { id: true, full_name: true } }, // instructor
          groups: {
            select: { id: true }, // count groups
          },
        },
      });

      // 3. Map UI-friendly result
      const data = courses.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        instructor: c.users
          ? { id: c.users.id, full_name: c.users.full_name }
          : null,
        groupCount: c.groups.length,
      }));

      return {
        message: 'Lấy khóa học của student thành công',
        data,
      };
    } catch (err) {
      throw new RpcException({
        statusCode: 500,
        message: 'Lỗi khi lấy danh sách khóa học',
      });
    }
  }

  async getAllStudents(id: number) {
    try {
      const students = await this.prisma.students.findMany({
        where: {
          student_groups: {
            some: {
              groups: {
                course_id: id,
              },
            },
          },
        },
        select: {
          id: true,
          student_code: true,
          year: true,
          users: {
            select: {
              full_name: true,
              email: true,
              username: true,
              avatar_url: true,
            },
          },
        },
        distinct: ['id'], // tránh trùng nếu sinh viên thuộc nhiều nhóm trong cùng khóa học
        orderBy: {
          student_code: 'asc',
        },
      });

      return {
        message: 'Lấy danh sách thành công',
        data: students,
      };
    } catch (error) {
      console.log('❌ ERROR getAllStudent:', error);
      throw new RpcException({
        statusCode: 500,
        message: 'Lỗi khi lấy danh sách khóa học',
      });
    }
  }

  async get(id: number) {
    try {
      const data = await this.prisma.courses.findFirst({
        where: { id },
        include: {
          users: {
            select: {
              id: true,
              full_name: true,
              email: true,
              avatar_url: true,
            },
          },
          semesters: true,
        },
      });
      if (!data)
        throw new RpcException({
          statusCode: 404,
          message: 'Khoá học không tồn tại',
        });
      return { message: 'Lấy khoá học thành công', data };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async create(instructorId: number, dto: any) {
    try {
      const {
        code,
        name,
        semester_id,
        sessions,
        groups, // [{ name: "Group A" }, { name: "Group A" }]
      } = dto;

      // ===============================
      // 1️⃣ Validate input
      // ===============================

      // Check duplicate course code in same semester
      const exist = await this.prisma.courses.findFirst({
        where: { code, semester_id },
      });

      if (exist) {
        throw new RpcException({
          statusCode: 400,
          message: 'Mã khoá học đã tồn tại trong học kỳ này',
        });
      }

      // Check instructor
      const instructor = await this.prisma.users.findFirst({
        where: { id: instructorId, role: 'instructor' },
      });

      if (!instructor) {
        throw new RpcException({
          statusCode: 400,
          message: 'Giảng viên không tồn tại hoặc không hợp lệ',
        });
      }

      // Check semester
      const semester = await this.prisma.semesters.findFirst({
        where: { id: semester_id },
      });

      if (!semester) {
        throw new RpcException({
          statusCode: 400,
          message: 'Học kỳ không tồn tại',
        });
      }

      // ===============================
      // 2️⃣ Validate groups
      // ===============================
      if (groups && groups.length > 0) {
        // Check empty names
        const hasEmptyName = groups.some(
          (g) => !g.name || g.name.trim() === '',
        );
        if (hasEmptyName) {
          throw new RpcException({
            statusCode: 400,
            message: 'Tên group không được để trống',
          });
        }

        // Check duplicates ONLY within this course
        const names = groups.map((g) => g.name.trim().toLowerCase());
        const nameSet = new Set(names);

        if (nameSet.size !== names.length) {
          throw new RpcException({
            statusCode: 400,
            message: 'Tên group không được trùng trong cùng khoá học',
          });
        }
      }

      // ===============================
      // 3️⃣ Create course + groups
      // ===============================
      const created = await this.prisma.courses.create({
        data: {
          name,
          code,
          sessions,
          semester_id,
          instructor_id: instructorId,

          groups: groups
            ? {
                create: groups.map((g) => ({
                  name: g.name.trim(),
                })),
              }
            : undefined,
        },
        include: {
          groups: true,
        },
      });

      return {
        message: 'Tạo khoá học thành công',
        data: created,
      };
    } catch (error: any) {
      if (error.code === 'P2003') {
        throw new RpcException({
          statusCode: 400,
          message:
            'Khoá ngoại không hợp lệ — instructor_id hoặc semester_id không tồn tại',
        });
      }

      if (error instanceof RpcException) throw error;

      throw new RpcException({
        statusCode: 500,
        message: error.message || 'Lỗi hệ thống khi tạo khoá học',
      });
    }
  }

  async update(id: number, dto: UpdateCourseDto) {
    try {
      const course = await this.prisma.courses.findFirst({ where: { id } });
      if (!course)
        throw new RpcException({
          statusCode: 404,
          message: 'Khoá học không tồn tại',
        });

      const data = await this.prisma.courses.update({
        where: { id },
        data: dto,
      });
      return { message: 'Cập nhật khoá học thành công', data };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }

  async delete(id: number) {
    try {
      const course = await this.prisma.courses.findFirst({ where: { id } });
      if (!course)
        throw new RpcException({
          statusCode: 404,
          message: 'Khoá học không tồn tại',
        });

      await this.prisma.courses.delete({ where: { id } });
      return { message: 'Xoá khoá học thành công' };
    } catch (error) {
      if (error instanceof RpcException) throw error;
      throw new RpcException({ statusCode: 500, message: error.message });
    }
  }
}
