import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import {
  assertFound,
  assertOrBadRequest,
  mapPrismaError,
} from 'src/common/utils/prisma-error.util';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';

const INSTRUCTOR_USER_ID = 2;
@Injectable()
export class StudentsService {
  constructor(
    private prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  /**
   * Lấy danh sách sinh viên (có thể lọc theo groupId)
   */
  async list(filter: { groupId?: number }) {
    try {
      if (filter?.groupId) {
        const group = await this.prisma.groups.findFirst({
          where: { id: +filter.groupId },
        });
        assertFound(group, 'Nhóm không tồn tại');

        const studentGroups = await this.prisma.student_groups.findMany({
          where: { group_id: +filter.groupId },
          include: {
            students: {
              include: {
                users: { select: { full_name: true, email: true } },
              },
            },
          },
        });

        const data = studentGroups.map((sg) => ({
          id: sg.students.id,
          student_code: sg.students.student_code,
          name: sg.students.users?.full_name,
          email: sg.students.users?.email,
        }));

        return {
          message: 'Lấy danh sách sinh viên theo nhóm thành công',
          data,
        };
      }

      // Không truyền groupId -> lấy toàn bộ
      const allStudents = await this.prisma.students.findMany({
        include: { users: { select: { full_name: true, email: true } } },
        orderBy: { id: 'asc' },
      });

      const data = allStudents.map((s) => ({
        id: s.id,
        student_code: s.student_code,
        name: s.users?.full_name,
        email: s.users?.email,
      }));

      return {
        message: 'Lấy toàn bộ danh sách sinh viên thành công',
        data,
      };
    } catch (err) {
      mapPrismaError(err, 'students.list');
    }
  }

  async getConversation(studentUserId: number) {
    try {
      const conversation = await this.prisma.conversations.findFirst({
        where: {
          instructor_id: INSTRUCTOR_USER_ID,
          student_user_id: studentUserId,
        },
        include: {
          instructor: {
            select: {
              id: true,
              full_name: true,
              email: true,
              avatar_url: true,
            },
          },
          studentUser: {
            select: {
              id: true,
              full_name: true,
              email: true,
              avatar_url: true,
              students: {
                select: {
                  id: true,
                  student_code: true,
                  year: true,
                },
              },
            },
          },
          messages: {
            orderBy: { created_at: 'asc' },
            include: {
              sender: {
                select: {
                  id: true,
                  full_name: true,
                  avatar_url: true,
                  role: true,
                },
              },
              receiver: {
                select: {
                  id: true,
                  full_name: true,
                  avatar_url: true,
                  role: true,
                },
              },
              attachments: true,
            },
          },
        },
      });

      assertFound(conversation, 'Cuộc trò chuyện không tồn tại');

      return {
        message: 'Lấy cuộc trò chuyện thành công',
        data: conversation,
      };
    } catch (err) {
      mapPrismaError(err, 'chat.getConversation');
    }
  }

  /** Instructor xem danh sách tất cả cuộc trò chuyện với sinh viên */
  async listConversations() {
    try {
      const conversations = await this.prisma.conversations.findMany({
        where: { instructor_id: INSTRUCTOR_USER_ID },
        orderBy: { updated_at: 'desc' },
        include: {
          studentUser: {
            select: {
              id: true,
              full_name: true,
              email: true,
              avatar_url: true,
              students: {
                select: {
                  id: true,
                  student_code: true,
                  year: true,
                },
              },
            },
          },
          messages: {
            orderBy: { created_at: 'desc' },
            take: 1, // chỉ lấy tin nhắn mới nhất cho preview
            include: {
              sender: {
                select: {
                  id: true,
                  full_name: true,
                  avatar_url: true,
                  role: true,
                },
              },
              attachments: true,
            },
          },
        },
      });

      return {
        message: 'Lấy danh sách cuộc trò chuyện thành công',
        data: conversations,
      };
    } catch (err) {
      mapPrismaError(err, 'chat.listConversations');
    }
  }

  /** Tạo conversation nếu chưa có giữa instructor (2) và studentUserId */
  async createConversation(studentUserId: number) {
    if (!studentUserId) {
      throw new Error('Student user id không hợp lệ');
    }

    // Instructor không được tự tạo với chính mình
    if (studentUserId === INSTRUCTOR_USER_ID) {
      throw new Error('Không thể tạo cuộc trò chuyện với chính mình');
    }

    // Kiểm tra student tồn tại
    const student = await this.prisma.users.findFirst({
      where: { id: studentUserId, role: 'student' },
    });
    assertFound(student, 'User không hợp lệ hoặc không phải sinh viên');

    // Tìm cuộc trò chuyện cũ
    let conversation = await this.prisma.conversations.findFirst({
      where: {
        instructor_id: INSTRUCTOR_USER_ID,
        student_user_id: studentUserId,
      },
    });

    if (!conversation) {
      conversation = await this.prisma.conversations.create({
        data: {
          instructor_id: INSTRUCTOR_USER_ID,
          student_user_id: studentUserId,
        },
      });
    }

    return {
      message: 'Mở cuộc trò chuyện thành công',
      data: conversation,
    };
  }

  /** Lấy lịch sử tin nhắn theo conversation */
  async getMessages(conversationId: number) {
    try {
      const conversation = await this.prisma.conversations.findFirst({
        where: { id: conversationId },
      });
      assertFound(conversation, 'Cuộc trò chuyện không tồn tại');

      const messages = await this.prisma.messages.findMany({
        where: { conversation_id: conversationId },
        orderBy: { created_at: 'asc' },
        include: {
          sender: {
            select: { id: true, full_name: true, avatar_url: true, role: true },
          },
          receiver: {
            select: { id: true, full_name: true, avatar_url: true, role: true },
          },
          attachments: true,
        },
      });

      return {
        message: 'Lấy danh sách tin nhắn thành công',
        data: messages,
      };
    } catch (err) {
      mapPrismaError(err, 'chat.getMessages');
    }
  }

  /** Gửi tin nhắn (có thể có nhiều file đính kèm) */
  /** Gửi tin nhắn (hỗ trợ nhiều file upload Cloudinary) */
  async sendMessage(body: {
    conversationId: number;
    senderId: number;
    content?: string;
    attachments?: {
      data: string; // base64
      file_name: string;
      file_type: string;
      file_size: number;
    }[];
  }) {
    const { conversationId, senderId, content, attachments } = body;

    try {
      const conversation = await this.prisma.conversations.findFirst({
        where: { id: conversationId },
      });
      assertFound(conversation, 'Cuộc trò chuyện không tồn tại');

      // Kiểm tra sender có thuộc conversation không
      if (
        senderId !== INSTRUCTOR_USER_ID &&
        senderId !== conversation.student_user_id
      ) {
        throw new Error('Sender không thuộc cuộc trò chuyện này');
      }

      // Xác định người nhận
      const receiverId =
        senderId === INSTRUCTOR_USER_ID
          ? conversation.student_user_id
          : INSTRUCTOR_USER_ID;

      // 1️⃣ Tạo tin nhắn trước
      const message = await this.prisma.messages.create({
        data: {
          conversation_id: conversationId,
          sender_id: senderId,
          receiver_id: receiverId,
          content: content ?? null,
        },
      });

      // 2️⃣ Upload file Cloudinary nếu có
      if (attachments?.length > 0) {
        const uploadedFiles = await Promise.all(
          attachments.map(async (file) => {
            const buffer = Buffer.from(file.data, 'base64');

            const uploaded = await this.cloudinary.uploadFile(
              buffer,
              file.file_name,
              file.file_type,
            );

            return {
              message_id: message.id,
              file_url: uploaded.url,
              file_name: file.file_name,
              file_type: file.file_type,
              file_size: file.file_size,
            };
          }),
        );

        await this.prisma.message_attachments.createMany({
          data: uploadedFiles,
        });
      }

      // 3️⃣ Cập nhật conversation activity
      await this.prisma.conversations.update({
        where: { id: conversationId },
        data: { updated_at: new Date() },
      });

      // 4️⃣ Instructor gửi → tạo notification cho Student
      if (senderId === INSTRUCTOR_USER_ID) {
        const student = await this.prisma.students.findFirst({
          where: { user_id: receiverId },
        });

        if (student) {
          await this.prisma.notifications.create({
            data: {
              student_id: student.id,
              title: 'Tin nhắn mới từ giảng viên',
              message: content ?? 'Bạn có tập tin đính kèm mới',
            },
          });
        }
      }

      // 5️⃣ Trả đầy đủ message sau upload
      const fullMessage = await this.prisma.messages.findFirst({
        where: { id: message.id },
        include: {
          sender: {
            select: { id: true, full_name: true, avatar_url: true, role: true },
          },
          receiver: {
            select: { id: true, full_name: true, avatar_url: true, role: true },
          },
          attachments: true,
        },
      });

      return {
        message: 'Gửi tin nhắn thành công',
        data: fullMessage,
      };
    } catch (err) {
      mapPrismaError(err, 'chat.sendMessage');
    }
  }

  /** Đánh dấu tất cả tin nhắn trong conversation là đã đọc với userId là người nhận */
  async markRead(conversationId: number, userId: number) {
    try {
      const conversation = await this.prisma.conversations.findFirst({
        where: { id: conversationId },
      });
      assertFound(conversation, 'Cuộc trò chuyện không tồn tại');

      const result = await this.prisma.messages.updateMany({
        where: {
          conversation_id: conversationId,
          receiver_id: userId,
          is_read: false,
        },
        data: { is_read: true },
      });

      return {
        message: 'Đánh dấu đã đọc thành công',
        count: result.count,
      };
    } catch (err) {
      mapPrismaError(err, 'chat.markRead');
    }
  }

  /**
   * Lấy chi tiết sinh viên
   */
  async detail(id: number) {
    try {
      const student = await this.prisma.students.findFirst({
        where: { id },
        include: {
          users: { select: { full_name: true, email: true } },
          student_groups: {
            include: {
              groups: { select: { id: true, name: true } },
            },
          },
        },
      });
      assertFound(student, 'Sinh viên không tồn tại');

      return { message: 'Lấy thông tin sinh viên thành công', data: student };
    } catch (err) {
      mapPrismaError(err, 'students.detail');
    }
  }

  /**
   * Tạo sinh viên mới
   */
  async create(dto: CreateStudentDto) {
    try {
      const existed = await this.prisma.students.findFirst({
        where: { student_code: dto.student_code },
      });
      assertOrBadRequest(!existed, 'Mã sinh viên đã tồn tại');

      // Kiểm tra user tồn tại
      const user = await this.prisma.users.findFirst({
        where: { id: dto.user_id },
      });
      assertFound(user, 'User không tồn tại');

      // Kiểm tra nhóm
      if (dto.group_ids?.length) {
        for (const gid of dto.group_ids) {
          const group = await this.prisma.groups.findFirst({
            where: { id: gid },
          });
          assertFound(group, `Nhóm ${gid} không tồn tại`);
        }
      }

      // ✅ Tạo student bằng connect tới user
      const student = await this.prisma.students.create({
        data: {
          student_code: dto.student_code,
          year: dto.year ?? null,
          users: { connect: { id: dto.user_id } },
        },
      });

      // ✅ Gắn nhóm
      if (dto.group_ids?.length) {
        for (const gid of dto.group_ids) {
          await this.prisma.student_groups.create({
            data: { student_id: student.id, group_id: gid },
          });
        }
      }

      return { message: 'Tạo sinh viên thành công', data: student };
    } catch (err) {
      mapPrismaError(err, 'students.create');
    }
  }

  /**
   * Cập nhật sinh viên
   */
  async update(id: number, dto: UpdateStudentDto) {
    try {
      const current = await this.prisma.students.findFirst({ where: { id } });
      assertFound(current, 'Sinh viên không tồn tại');

      if (dto.student_code && dto.student_code !== current.student_code) {
        const dup = await this.prisma.students.findFirst({
          where: { student_code: dto.student_code },
        });
        assertOrBadRequest(!dup, 'Mã sinh viên đã tồn tại');
      }

      if (dto.user_id) {
        const user = await this.prisma.users.findFirst({
          where: { id: dto.user_id },
        });
        assertFound(user, 'User không tồn tại');
      }

      const updated = await this.prisma.students.update({
        where: { id },
        data: {
          student_code: dto.student_code ?? current.student_code,
          year: dto.year ?? current.year,
          ...(dto.user_id ? { users: { connect: { id: dto.user_id } } } : {}),
        },
      });

      // Cập nhật nhóm
      if (dto.group_ids) {
        await this.prisma.student_groups.deleteMany({
          where: { student_id: id },
        });
        for (const gid of dto.group_ids) {
          await this.prisma.student_groups.create({
            data: { student_id: id, group_id: gid },
          });
        }
      }

      return { message: 'Cập nhật sinh viên thành công', data: updated };
    } catch (err) {
      mapPrismaError(err, 'students.update');
    }
  }

  /**
   * Xóa sinh viên
   */
  async delete(id: number) {
    try {
      const student = await this.prisma.students.findFirst({ where: { id } });
      assertFound(student, 'Sinh viên không tồn tại');

      await this.prisma.student_groups.deleteMany({
        where: { student_id: id },
      });

      await this.prisma.students.delete({ where: { id } });

      return { message: 'Xoá sinh viên thành công' };
    } catch (err) {
      mapPrismaError(err, 'students.delete');
    }
  }

  /**
   * Import CSV sinh viên
   */
  async importCsv(payload: { rows: any[]; preview?: boolean }) {
    try {
      const rows = payload?.rows ?? [];
      assertOrBadRequest(rows.length > 0, 'Không có dữ liệu để import');

      const preview = [];

      for (const [i, r] of rows.entries()) {
        const student_code = String(r.student_code || '').trim();
        const user_id = r.user_id ? Number(r.user_id) : null;
        const year = r.year ? Number(r.year) : null;
        const group_ids = Array.isArray(r.group_ids)
          ? r.group_ids.map((id) => Number(id))
          : r.group_id
            ? [Number(r.group_id)]
            : [];

        if (!student_code || !user_id) {
          preview.push({
            index: i,
            student_code,
            status: 'invalid',
            reason: 'Thiếu student_code hoặc user_id',
          });
          continue;
        }

        const user = await this.prisma.users.findFirst({
          where: { id: user_id },
        });
        if (!user) {
          preview.push({
            index: i,
            student_code,
            status: 'invalid',
            reason: `User ${user_id} không tồn tại`,
          });
          continue;
        }

        const dup = await this.prisma.students.findFirst({
          where: { student_code },
        });
        if (dup) {
          preview.push({
            index: i,
            student_code,
            status: 'duplicate',
            reason: 'Mã sinh viên đã tồn tại',
          });
          continue;
        }

        const invalidGroups = [];
        for (const gid of group_ids) {
          const group = await this.prisma.groups.findFirst({
            where: { id: gid },
          });
          if (!group) invalidGroups.push(gid);
        }

        if (invalidGroups.length > 0) {
          preview.push({
            index: i,
            student_code,
            status: 'invalid',
            reason: `Nhóm không tồn tại: ${invalidGroups.join(', ')}`,
          });
          continue;
        }

        preview.push({
          index: i,
          student_code,
          user_id,
          year,
          group_ids,
          status: 'will_add',
        });
      }

      if (payload.preview) {
        return { message: 'Preview import sinh viên', data: preview };
      }

      const toInsert = preview.filter((r) => r.status === 'will_add');
      for (const row of toInsert) {
        const student = await this.prisma.students.create({
          data: {
            student_code: row.student_code,
            year: row.year ?? null,
            users: { connect: { id: row.user_id } },
          },
        });

        if (row.group_ids?.length) {
          for (const gid of row.group_ids) {
            await this.prisma.student_groups.create({
              data: { student_id: student.id, group_id: gid },
            });
          }
        }
      }

      return {
        message: 'Import sinh viên hoàn tất',
        data: {
          total: rows.length,
          inserted: toInsert.length,
          skipped: rows.length - toInsert.length,
          preview,
        },
      };
    } catch (err) {
      mapPrismaError(err, 'students.importCsv');
    }
  }
}
