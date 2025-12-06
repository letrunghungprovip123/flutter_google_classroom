import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { RMQ_PATTERN_SUBMISSIONS } from 'src/common/constants/rmq.pattern';
import { SubmissionsService } from './submissions.service';
import { CreateSubmissionDto } from './dto/create-submission.dto';
import { GradeSubmissionDto } from './dto/grade-submission.dto';

@Controller('submissions')
export class SubmissionsController {
  constructor(private readonly service: SubmissionsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_SUBMISSIONS.CREATE })
  create(@Payload() payload: any) {
    const { submission, attachments } = payload;
    return this.service.create(submission, attachments);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SUBMISSIONS.GET_BY_ASSIGNMENT })
  list(@Payload() assignmentId: number) {
    return this.service.listByAssignment(+assignmentId);
  }

  @MessagePattern({cmd : RMQ_PATTERN_SUBMISSIONS.GET_MY})
  getMySubmission(@Payload() data : any){
    return this.service.getMySubmission(data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SUBMISSIONS.GRADE })
  grade(@Payload() dto: GradeSubmissionDto) {
    return this.service.grade(dto);
  }
}
