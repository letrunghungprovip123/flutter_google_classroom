import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  Inject,
  ParseIntPipe,
  UseGuards,
  UseInterceptors,
  Request,
  UploadedFiles,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { FilesInterceptor } from '@nestjs/platform-express';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_MATERIALS } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('materials')
export class MaterialsController {
  constructor(
    @Inject('USER_SERVICE') private readonly client: ClientProxy, // materials thuộc user-course-service
  ) {}

  // GET /materials?courseId=
  @Get()
  async list(@Query('courseId') courseId?: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_MATERIALS.GET_BY_COURSE },
          courseId ? { courseId: +courseId } : {},
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // GET /materials/:id
  @Get(':id')
  async detail(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_MATERIALS.GET_BY_ID }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // POST /materials
  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FilesInterceptor('files'))
  async create(
    @Request() req: any,
    @Body() body: any,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    try {
      const instructor_id = req.user.id;

      const material = {
        course_id: Number(body.course_id),
        instructor_id,
        title: body.title,
        description: body.description ?? null,
      };

      const attachments = files.map((file) => ({
        buffer: file.buffer.toString('base64'),
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      }));

      const payload = { material, attachments };

      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_MATERIALS.CREATE }, payload),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // DELETE /materials/:id
  @Delete(':id')
  async delete(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_MATERIALS.DELETE }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
