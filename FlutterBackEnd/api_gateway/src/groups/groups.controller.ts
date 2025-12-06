import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  Inject,
  Patch,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_GROUPS, RMQ_PATTERN_STUDENT_GROUP } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';

@Controller('groups')
export class GroupsController {
  constructor(@Inject('USER_SERVICE') private readonly client: ClientProxy) {}

  @Get()
  async list(@Query('courseId') courseId: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_GROUPS.LIST },
          { courseId: +courseId },
        ),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Post()
  async create(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_GROUPS.CREATE }, dto),
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
          { cmd: RMQ_PATTERN_GROUPS.UPDATE },
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
        this.client.send({ cmd: RMQ_PATTERN_GROUPS.DELETE }, +id),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @Post('import')
  async importCsv(@Body() body: { rows: any[]; preview?: boolean }) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_GROUPS.IMPORT_CSV }, body),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  // gateway controller

  // Preview import student-group cho 1 group cụ thể
  @Post('student-groups/:groupId/import/preview')
  async previewGroupImport(
    @Param('groupId') groupId: string,
    @Body() dto: { rows: { student_code: string }[] },
  ) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENT_GROUP.IMPORT_PREVIEW },
          { groupId: Number(groupId), rows: dto.rows },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  // Confirm import (createMany student_groups)
  @Post('student-groups/:groupId/import/confirm')
  async confirmGroupImport(
    @Param('groupId') groupId: string,
    @Body() dto: { rows: { student_code: string; status?: string }[] },
  ) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENT_GROUP.IMPORT_CONFIRM },
          { groupId: Number(groupId), rows: dto.rows },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  // Tạo 1 student-group (thêm 1 student vào group)
  @Post('student-groups/:groupId')
  async addStudentToGroup(
    @Param('groupId') groupId: string,
    @Body() dto: { student_code: string },
  ) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENT_GROUP.CREATE_ONE },
          { groupId: Number(groupId), ...dto },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  // Xoá student ra khỏi group (xoá bản ghi student_groups)
  @Delete('student-groups/:groupId/:studentId')
  async removeStudentFromGroup(
    @Param('groupId') groupId: string,
    @Param('studentId') studentId: string,
  ) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_STUDENT_GROUP.REMOVE_ONE },
          { groupId: Number(groupId), studentId: Number(studentId) },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }
}
