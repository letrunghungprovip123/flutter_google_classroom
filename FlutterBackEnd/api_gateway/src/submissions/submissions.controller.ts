import {
  Controller,
  Post,
  Get,
  Put,
  Param,
  Body,
  Inject,
  UseInterceptors,
  UploadedFiles,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { FilesInterceptor } from '@nestjs/platform-express';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_SUBMISSIONS } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('submissions')
export class SubmissionsController {
  constructor(
    @Inject('ASSIGNMENT_SERVICE') private readonly client: ClientProxy,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FilesInterceptor('files'))
  async create(
    @Request() req,
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    try {
      const userId = req.user.id; // 🔥 Lấy từ token

      const submission = {
        assignment_id: Number(body.assignment_id),
        student_id: Number(userId), // 🔥 Không dùng body
      };

      const attachments = files.map((file) => ({
        buffer: file.buffer.toString('base64'),
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      }));

      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_SUBMISSIONS.CREATE },
          { submission, attachments },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Get(':assignmentId')
  async list(@Param('assignmentId') id: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_SUBMISSIONS.GET_BY_ASSIGNMENT },
          +id,
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('my/:assignmentId')
  async getMySubmission(@Param('assignmentId') id: string, @Request() req) {
    try {
      const userId = req.user.id; // lấy từ access token

      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_SUBMISSIONS.GET_MY },
          { assignmentId: +id, userId },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Put(':id/grade')
  async grade(@Param('id') id: string, @Body() body: any) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_SUBMISSIONS.GRADE },
          { submission_id: +id, grade: +body.grade },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
