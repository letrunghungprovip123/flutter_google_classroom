import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AnnoucementsService } from './annoucements.service';
import { UpdateAnnoucementDto } from './dto/update-annoucement.dto';
import { RMQ_PATTERN_ANNOUNCEMENTS, RMQ_PATTERN_COMMENTS } from 'src/common/constants/rmq.pattern';

@Controller()
export class AnnoucementsController {
  constructor(private readonly service: AnnoucementsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.CREATE })
  create(@Payload() dto: any) {
    const { announcement, attachments } = dto;
    return this.service.create(announcement, attachments);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.GET_BY_COURSE })
  getByCourse(@Payload() course_id: number) {
    return this.service.getByCourse(course_id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.DETAIL })
  detail(@Payload() id: number) {
    return this.service.detail(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.UPDATE })
  update(@Payload() payload: { id: number; dto: any }) {
    return this.service.update(payload.id, payload.dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_ANNOUNCEMENTS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COMMENTS.CREATE })
  createComment(@Payload() dto) {
    return this.service.createComment(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COMMENTS.GET_BY_ANNOUNCEMENT })
  getByAnnouncement(@Payload() annId: number) {
    return this.service.getByAnnouncement(annId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COMMENTS.DELETE })
  deleteComment(@Payload() dto) {
    return this.service.deleteComment(dto.commentId, dto.userId);
  }
}
