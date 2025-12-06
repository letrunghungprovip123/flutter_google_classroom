import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { GroupsService } from './groups.service';
import { RMQ_PATTERN_GROUPS, RMQ_PATTERN_STUDENT_GROUP } from 'src/common/constants/rmq.pattern';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';

@Controller()
export class GroupsController {
  constructor(private readonly service: GroupsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_GROUPS.LIST })
  list(@Payload() filter: { courseId: number }) {
    return this.service.list(filter);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_GROUPS.CREATE })
  create(@Payload() dto: CreateGroupDto) {
    return this.service.create(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_GROUPS.UPDATE })
  update(@Payload() payload: { id: number; data: UpdateGroupDto }) {
    return this.service.update(+payload.id, payload.data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_GROUPS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_GROUPS.IMPORT_CSV })
  importCsv(@Payload() payload: { rows: any[]; preview?: boolean }) {
    return this.service.importCsv(payload);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT_GROUP.IMPORT_PREVIEW })
  async previewImportStudentGroup(
    @Payload()
    data: {
      groupId: number;
      rows: { student_code: string }[];
    },
  ) {
    return this.service.previewImport(data.groupId, data.rows);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT_GROUP.IMPORT_CONFIRM })
  async confirmImportStudentGroup(
    @Payload()
    data: {
      groupId: number;
      rows: { student_code: string; status?: string }[];
    },
  ) {
    return this.service.confirmImport(data.groupId, data.rows);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT_GROUP.CREATE_ONE })
  async createOneStudentGroup(
    @Payload() data: { groupId: number; student_code: string },
  ) {
    return this.service.addOne(data.groupId, data.student_code);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT_GROUP.REMOVE_ONE })
  async removeOneStudentGroup(
    @Payload() data: { groupId: number; studentId: number },
  ) {
    return this.service.removeOne(data.groupId, data.studentId);
  }
}
