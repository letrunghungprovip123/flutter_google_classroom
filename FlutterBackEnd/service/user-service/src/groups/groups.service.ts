import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { RpcException } from '@nestjs/microservices';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import {
  assertFound,
  assertOrBadRequest,
  mapPrismaError,
} from 'src/common/utils/prisma-error.util';

@Injectable()
export class GroupsService {
  constructor(private prisma: PrismaService) {}

  async previewImport(groupId: number, rows: { student_code: string }[]) {
    // 0. Check group tồn tại
    const group = await this.prisma.groups.findUnique({
      where: { id: groupId },
    });
    if (!group) {
      throw new RpcException({
        statusCode: 400,
        message: 'Group không tồn tại',
      });
    }

    const result = [];
    const seenCode = new Set<string>();

    for (const row of rows) {
      const code = (row.student_code || '').trim();

      // 1️⃣ Thiếu student_code
      if (!code) {
        result.push({
          ...row,
          status: 'error_missing_code',
          error: 'Thiếu student_code',
        });
        continue;
      }

      // 2️⃣ Trùng trong chính file CSV
      if (seenCode.has(code)) {
        result.push({
          ...row,
          student_code: code,
          status: 'duplicate_in_file',
          error: 'student_code bị trùng trong file CSV',
        });
        continue;
      }
      seenCode.add(code);

      // 3️⃣ Kiểm tra student_code tồn tại trong DB
      const student = await this.prisma.students.findUnique({
        where: { student_code: code },
      });

      if (!student) {
        result.push({
          ...row,
          student_code: code,
          status: 'student_not_found',
          error: 'Không tìm thấy student với student_code này',
        });
        continue;
      }

      // 4️⃣ Kiểm tra xem student đã thuộc group này chưa
      const existedMap = await this.prisma.student_groups.findFirst({
        where: {
          group_id: groupId,
          student_id: student.id,
        },
      });

      if (existedMap) {
        result.push({
          ...row,
          student_code: code,
          status: 'already_in_group',
          error: 'Student đã nằm trong group này',
        });
        continue;
      }

      // 5️⃣ OK - sẽ add
      result.push({
        ...row,
        student_code: code,
        status: 'will_add',
      });
    }

    return {
      message: 'Preview import student-group thành công',
      rows: result,
    };
  }

  async confirmImport(
    groupId: number,
    rows: { student_code: string; status?: string }[],
  ) {
    const group = await this.prisma.groups.findUnique({
      where: { id: groupId },
    });
    if (!group) {
      throw new RpcException({
        statusCode: 400,
        message: 'Group không tồn tại',
      });
    }

    const results = [];

    for (const r of rows) {
      const code = (r.student_code || '').trim();

      // Bỏ qua những dòng không phải will_add
      if (r.status && r.status !== 'will_add') {
        results.push({
          ...r,
          student_code: code,
          status: r.status,
          note: 'Bỏ qua vì không ở trạng thái will_add',
        });
        continue;
      }

      try {
        const student = await this.prisma.students.findUnique({
          where: { student_code: code },
        });

        if (!student) {
          results.push({
            ...r,
            student_code: code,
            status: 'failed_student_not_found',
          });
          continue;
        }

        // Check lần nữa xem đã thuộc group chưa
        const existed = await this.prisma.student_groups.findFirst({
          where: {
            group_id: groupId,
            student_id: student.id,
          },
        });

        if (existed) {
          results.push({
            ...r,
            student_code: code,
            status: 'skipped_already_in_group',
          });
          continue;
        }

        await this.prisma.student_groups.create({
          data: {
            group_id: groupId,
            student_id: student.id,
          },
        });

        results.push({
          ...r,
          student_code: code,
          status: 'added',
        });
      } catch (err) {
        results.push({
          ...r,
          student_code: code,
          status: 'failed',
          error: err.message,
        });
      }
    }

    return {
      message: 'Import student-group completed',
      results,
    };
  }

  async addOne(groupId: number, student_code: string) {
    const code = (student_code || '').trim();

    const group = await this.prisma.groups.findUnique({
      where: { id: groupId },
    });
    if (!group) {
      throw new RpcException({
        statusCode: 400,
        message: 'Group không tồn tại',
      });
    }

    const student = await this.prisma.students.findUnique({
      where: { student_code: code },
    });
    if (!student) {
      throw new RpcException({
        statusCode: 400,
        message: 'Student không tồn tại với student_code này',
      });
    }

    const existed = await this.prisma.student_groups.findFirst({
      where: {
        group_id: groupId,
        student_id: student.id,
      },
    });

    if (existed) {
      throw new RpcException({
        statusCode: 400,
        message: 'Student đã nằm trong group này',
      });
    }

    const created = await this.prisma.student_groups.create({
      data: {
        group_id: groupId,
        student_id: student.id,
      },
    });

    return {
      message: 'Thêm student vào group thành công',
      data: created,
    };
  }

  async removeOne(groupId: number, studentId: number) {
    // Không cần throw nếu không tồn tại, nhưng để rõ ràng hơn:
    const existed = await this.prisma.student_groups.findFirst({
      where: {
        group_id: groupId,
        student_id: studentId,
      },
    });

    if (!existed) {
      throw new RpcException({
        statusCode: 400,
        message: 'Student không thuộc group này hoặc đã bị xoá',
      });
    }

    await this.prisma.student_groups.delete({
      where: {
        id: existed.id,
      },
    });

    return {
      message: 'Xoá student khỏi group thành công',
    };
  }

  async list(filter: { courseId?: number }) {
    try {
      if (filter?.courseId) {
        const course = await this.prisma.courses.findFirst({
          where: { id: +filter.courseId },
        });
        assertFound(course, 'Khoá học không tồn tại');

        const groups = await this.prisma.groups.findMany({
          where: { course_id: +filter.courseId },
          orderBy: { id: 'asc' },
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
        });

        const result = groups.map((g) => ({
          id: g.id,
          name: g.name,
          course_id: g.course_id,
          students: g.student_groups.map((sg) => ({
            student_group_id: sg.id, // 🆕 Thêm ID để xoá nhanh
            student_id: sg.students.id,
            student_code: sg.students.student_code,
            year: sg.students.year,
            user: {
              id: sg.students.users?.id,
              full_name: sg.students.users?.full_name,
              email: sg.students.users?.email,
              avatar_url: sg.students.users?.avatar_url,
            },
          })),
        }));

        return {
          message: 'Lấy nhóm theo khoá học thành công',
          data: result,
        };
      }

      // Không filter → không cần load students để giảm tải
      const allGroups = await this.prisma.groups.findMany({
        orderBy: [{ course_id: 'asc' }, { id: 'asc' }],
      });

      return {
        message: 'Lấy toàn bộ danh sách nhóm thành công',
        data: allGroups,
      };
    } catch (err) {
      mapPrismaError(err, 'groups.list');
    }
  }

  async create(dto: CreateGroupDto) {
    try {
      const course = await this.prisma.courses.findFirst({
        where: { id: dto.course_id },
      });
      assertFound(course, 'Khoá học không tồn tại');

      const dup = await this.prisma.groups.findFirst({
        where: { course_id: dto.course_id, name: dto.name },
      });
      assertOrBadRequest(!dup, 'Nhóm đã tồn tại trong khoá học');

      const data = await this.prisma.groups.create({ data: dto });
      return { message: 'Tạo nhóm thành công', data };
    } catch (err) {
      mapPrismaError(err, 'groups.create');
    }
  }

  async update(id: number, dto: UpdateGroupDto) {
    try {
      const current = await this.prisma.groups.findFirst({ where: { id } });
      assertFound(current, 'Nhóm không tồn tại');

      if (dto.course_id) {
        const course = await this.prisma.courses.findFirst({
          where: { id: dto.course_id },
        });
        assertFound(course, 'Khoá học không tồn tại');
      }

      const name = dto.name ?? current.name;
      const courseId = dto.course_id ?? current.course_id;
      const dup = await this.prisma.groups.findFirst({
        where: { course_id: courseId, name, NOT: { id } },
      });
      assertOrBadRequest(!dup, 'Tên nhóm đã tồn tại trong khoá học');

      const data = await this.prisma.groups.update({
        where: { id },
        data: dto,
      });
      return { message: 'Cập nhật nhóm thành công', data };
    } catch (err) {
      mapPrismaError(err, 'groups.update');
    }
  }

  async delete(id: number) {
    try {
      const current = await this.prisma.groups.findFirst({ where: { id } });
      assertFound(current, 'Nhóm không tồn tại');

      await this.prisma.groups.delete({ where: { id } });
      return { message: 'Xoá nhóm thành công' };
    } catch (err) {
      mapPrismaError(err, 'groups.delete');
    }
  }

  /**
   * CSV import preview/commit
   */
  async importCsv(payload: { rows: any[]; preview?: boolean }) {
    try {
      const rows = payload?.rows ?? [];
      assertOrBadRequest(rows.length > 0, 'Không có dữ liệu để import');

      const preview = [];
      for (const [i, r] of rows.entries()) {
        const course_id = Number(r.course_id);
        const name = String(r.name || '').trim();

        if (!course_id || !name) {
          preview.push({
            index: i,
            course_id,
            name,
            status: 'invalid',
            reason: 'Thiếu course_id hoặc name',
          });
          continue;
        }

        const course = await this.prisma.courses.findFirst({
          where: { id: course_id },
        });
        if (!course) {
          preview.push({
            index: i,
            course_id,
            name,
            status: 'invalid',
            reason: 'Khoá học không tồn tại',
          });
          continue;
        }

        const dup = await this.prisma.groups.findFirst({
          where: { course_id, name },
        });

        if (dup) {
          preview.push({
            index: i,
            course_id,
            name,
            status: 'duplicate',
            reason: 'Nhóm đã tồn tại',
          });
        } else {
          preview.push({ index: i, course_id, name, status: 'will_add' });
        }
      }

      if (payload.preview) {
        return { message: 'Preview import nhóm', data: preview };
      }

      const toInsert = preview.filter((p) => p.status === 'will_add');
      for (const row of toInsert) {
        await this.prisma.groups.create({
          data: { course_id: row.course_id, name: row.name },
        });
      }

      return {
        message: 'Import nhóm hoàn tất',
        data: {
          total: rows.length,
          inserted: toInsert.length,
          skipped: rows.length - toInsert.length,
          preview,
        },
      };
    } catch (err) {
      mapPrismaError(err, 'groups.importCsv');
    }
  }
}
