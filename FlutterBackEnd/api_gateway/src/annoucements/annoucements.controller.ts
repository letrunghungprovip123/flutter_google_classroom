import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  Inject,
  UseInterceptors,
  UploadedFiles,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { FilesInterceptor } from '@nestjs/platform-express';
import { lastValueFrom } from 'rxjs';
import {
  RMQ_PATTERN_ANNOUNCEMENTS,
  RMQ_PATTERN_COMMENTS,
} from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('announcements')
export class AnnoucementsController {
  constructor(
    @Inject('NOTIFICATION_SERVICE') private readonly client: ClientProxy,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FilesInterceptor('files'))
  async create(
    @Request() req: any,
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    try {
      // ------------------------------
      // 1. Chuẩn hoá announcement DTO
      const user_id = req.user.id;
      // ------------------------------
      const announcement = {
        course_id: Number(body.course_id),
        user_id: Number(user_id),
        title: body.title,
        content: body.content,
      };

      // ------------------------------
      // 2. Chuẩn hoá attachments gửi xuống MS
      //    (vẫn giữ buffer dạng base64 - CLOUDINARY UPLOAD Ở MICRO SERVICE)
      // ------------------------------
      const attachments = files.map((file) => ({
        buffer: file.buffer.toString('base64'),
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      }));

      // ------------------------------
      // 3. Payload gửi RabbitMQ
      // ------------------------------
      const payload = { announcement, attachments };
      // console.log(payload);
      // ------------------------------
      // 4. Gửi xuống announcement-service
      // ------------------------------
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.CREATE }, payload),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/comments')
  async createComment(
    @Param('id') annId: string,
    @Body() body: { content: string },
    @Request() req,
  ) {
    try {
      const userId = req.user.id;

      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COMMENTS.CREATE },
          {
            announcementId: +annId,
            userId,
            content: body.content,
          },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // =============== GET COMMENTS ==================
  @UseGuards(JwtAuthGuard)
  @Get(':id/comments')
  async getComments(@Param('id') annId: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COMMENTS.GET_BY_ANNOUNCEMENT },
          +annId,
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // =============== DELETE COMMENT ==================
  @UseGuards(JwtAuthGuard)
  @Delete('comments/:commentId')
  async deleteComment(@Param('commentId') commentId: string, @Request() req) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COMMENTS.DELETE },
          { commentId: +commentId, userId: req.user.id },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Get()
  async getByCourse(@Query('courseId') courseId: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_ANNOUNCEMENTS.GET_BY_COURSE },
          +courseId,
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.DETAIL }, +id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_ANNOUNCEMENTS.UPDATE },
          { id: +id, dto },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.DELETE }, +id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
