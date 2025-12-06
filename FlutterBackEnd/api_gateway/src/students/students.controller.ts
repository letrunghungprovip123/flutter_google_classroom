import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Query,
  Body,
  Inject,
  Patch,
  UseGuards,
  UseInterceptors,
  Request,
  UploadedFiles,
} from '@nestjs/common';
import { ClientProxy, RpcException } from '@nestjs/microservices';
import { FilesInterceptor } from '@nestjs/platform-express';
import { lastValueFrom } from 'rxjs';
import {
  RMQ_PATTERN_CHAT,
  RMQ_PATTERN_STUDENTS,
} from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('students')
export class StudentsController {
  constructor(@Inject('USER_SERVICE') private readonly client: ClientProxy) {}

  @Get()
  async list(@Query('groupId') groupId?: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENTS.LIST },
          { groupId: groupId ? +groupId : undefined },
        ),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  // === CHAT API KHÔNG TRÙNG ROUTE ===

  // 🔹 Student lấy conversation của mình
  @UseGuards(JwtAuthGuard)
  @Get('chat/conversation')
  getConversation(@Request() req: any) {
    const studentUserId = req.user.id;
    return lastValueFrom(
      this.client.send(
        { cmd: RMQ_PATTERN_CHAT.GET_CONVERSATION },
        studentUserId,
      ),
    );
  }

  // 🔹 Instructor xem tất cả conversations
  @UseGuards(JwtAuthGuard)
  @Get('chat/conversations')
  async listConversations(@Request() req: any) {
    const instructorId = req.user.id; // user_id = 2

    return await lastValueFrom(
      this.client.send(
        { cmd: RMQ_PATTERN_CHAT.LIST_CONVERSATIONS },
        instructorId, // ❌ null → ✔ number
      ),
    );
  }

  // 🔹 Student tạo conversation với instructor
  @UseGuards(JwtAuthGuard)
  @Post('chat/conversation')
  createConversation(
    @Request() req: any,
    @Body('studentUserId') studentUserId?: number,
  ) {
    const loggedInId = req.user.id;

    return lastValueFrom(
      this.client.send(
        { cmd: RMQ_PATTERN_CHAT.CREATE_CONVERSATION },
        studentUserId ?? loggedInId,
      ),
    );
  }

  // 🔹 Lấy messages trong conversation
  @UseGuards(JwtAuthGuard)
  @Get('chat/:conversationId/messages')
  getMessages(@Param('conversationId') conversationId: string) {
    return lastValueFrom(
      this.client.send({ cmd: RMQ_PATTERN_CHAT.GET_MESSAGES }, +conversationId),
    );
  }

  // 🔹 Gửi tin nhắn
  @UseGuards(JwtAuthGuard)
  @Post('chat/send')
  @UseInterceptors(FilesInterceptor('files'))
  async sendMessage(
    @Request() req: any,
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    try {
      const senderId = req.user.id;

      if (!body.conversationId) {
        throw new RpcException('conversationId is required');
      }

      const conversationId = Number(body.conversationId);

      // 🔥 Loại file rỗng hoặc lỗi
      const validFiles =
        files
          ?.filter((file) => file && file.size > 0)
          .map((file) => ({
            data: file.buffer.toString('base64'),
            file_name: file.originalname,
            file_type: file.mimetype,
            file_size: file.size,
          })) ?? [];

      const payload = {
        conversationId,
        senderId,
        content: body.content || null,
        attachments: validFiles,
      };

      console.log('📌 SEND PAYLOAD:', {
        conversationId,
        senderId,
        content: payload.content,
        files_count: validFiles.length,
      });

      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_CHAT.SEND_MESSAGE }, payload),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  // 🔹 Mark read
  @UseGuards(JwtAuthGuard)
  @Patch('chat/:conversationId/mark-read')
  markRead(
    @Request() req: any,
    @Param('conversationId') conversationId: string,
  ) {
    const userId = req.user.id;
    return lastValueFrom(
      this.client.send(
        { cmd: RMQ_PATTERN_CHAT.MARK_READ },
        { conversationId: +conversationId, userId },
      ),
    );
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_STUDENTS.DETAIL }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Post()
  async create(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_STUDENTS.CREATE }, dto),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENTS.UPDATE },
          { id: +id, data: dto },
        ),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_STUDENTS.DELETE }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Post('import')
  async importCsv(@Body() body: { rows: any[]; preview?: boolean }) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_STUDENTS.IMPORT_CSV }, body),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }
}
