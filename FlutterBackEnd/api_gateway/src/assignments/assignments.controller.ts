// api-gateway/src/assignments/assignments.controller.ts
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
  InternalServerErrorException,
  Patch,
  UseInterceptors,
  UploadedFiles,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { FilesInterceptor } from '@nestjs/platform-express';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_ASSIGNMENTS } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('assignments')
export class AssignmentsController {
  constructor(
    @Inject('ASSIGNMENT_SERVICE') private readonly client: ClientProxy,
  ) {}

  @Get()
  async list(@Query('courseId') courseId?: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_ASSIGNMENTS.GET },
          { courseId: courseId ? +courseId : undefined },
        ),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ASSIGNMENTS.GET_BY_ID }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FilesInterceptor('files'))
  async create(
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
    @Request() req: any,
  ) {
    try {
      const instructor_id = req.user.id;
      // 1. Chuẩn hoá Assignment DTO
      const assignment = {
        course_id: Number(body.course_id),
        instructor_id: Number(instructor_id),
        title: body.title,
        description: body.description ?? null,
        start_date: body.start_date ?? null,
        deadline: body.deadline ?? null,
        late_deadline: body.late_deadline ?? null,
        allow_late: body.allow_late === 'true' ? true : false,
        max_attempts: body.max_attempts ? Number(body.max_attempts) : 1,
        file_format: body.file_format ?? null,
        file_size_limit_mb: body.file_size_limit_mb
          ? Number(body.file_size_limit_mb)
          : 10,
      };

      let attachments = [];
      if (files) {
        // 2. Chuẩn hoá attachments gửi xuống MS (giữ buffer base64)
        attachments = files.map((file) => ({
          buffer: file.buffer.toString('base64'),
          originalname: file.originalname,
          mimetype: file.mimetype,
          size: file.size,
        }));
      }
      // 3. Payload gửi xuống microservice
      const payload = { assignment, attachments };

      // 4. Gửi xuống assignments-service qua RMQ
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ASSIGNMENTS.CREATE }, payload),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Patch(':id')
  @UseInterceptors(FilesInterceptor('files'))
  async update(
    @Param('id') id: string,
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    try {
      // 1. Chuẩn hoá Assignment DTO gửi xuống MS
      const assignment = {
        id: Number(id),
        title: body.title,
        description: body.description ?? null,
        start_date: body.start_date ?? null,
        deadline: body.deadline ?? null,
        late_deadline: body.late_deadline ?? null,
        allow_late: body.allow_late === 'true',
        max_attempts: body.max_attempts ? Number(body.max_attempts) : undefined,
        file_format: body.file_format ?? undefined,
        file_size_limit_mb: body.file_size_limit_mb
          ? Number(body.file_size_limit_mb)
          : undefined,
        course_id: body.course_id ? Number(body.course_id) : undefined,
        instructor_id: body.instructor_id
          ? Number(body.instructor_id)
          : undefined,
      };

      // 2. Chuẩn hóa attachments giống POST
      const attachments = files.map((file) => ({
        buffer: file.buffer.toString('base64'),
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      }));

      // 3. Payload chuẩn
      const payload = { assignment, attachments };

      // 4. Gửi xuống MS
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ASSIGNMENTS.UPDATE }, payload),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ASSIGNMENTS.DELETE }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Get(':id/summary')
  async summary(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_ASSIGNMENTS.SUMMARY }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }
}
