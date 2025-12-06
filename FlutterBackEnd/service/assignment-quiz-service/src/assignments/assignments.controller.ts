// assignment-service/src/assignments/assignments.controller.ts
import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AssignmentsService } from './assignments.service';
import { RMQ_PATTERN_ASSIGNMENTS } from 'src/common/constants/rmq.pattern';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { UpdateAssignmentDto } from './dto/update-assignment.dto';

@Controller('assignments')
export class AssignmentsController {
  constructor(private readonly service: AssignmentsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.GET })
  list(@Payload() filter: { courseId?: number }) {
    return this.service.list(filter || {});
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.GET_BY_ID })
  detail(@Payload() id: number) {
    return this.service.detail(+id);
  }
  
  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.CREATE })
  create(@Payload() payload: any) {
    const { assignment, attachments } = payload;
    return this.service.create(assignment, attachments);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.UPDATE })
  update(@Payload() payload: any) {
    const { assignment, attachments } = payload;

    // id nằm trong assignment.id
    return this.service.update(assignment.id, assignment, attachments);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ASSIGNMENTS.SUMMARY })
  summary(@Payload() id: number) {
    return this.service.summary(+id);
  }
}
