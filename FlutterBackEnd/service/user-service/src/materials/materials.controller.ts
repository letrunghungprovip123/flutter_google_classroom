import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { MaterialsService } from './materials.service';
import { RMQ_PATTERN_MATERIALS } from 'src/common/constants/rmq.pattern';
import { CreateMaterialDto } from './dto/create-material.dto';
import { UpdateMaterialDto } from './dto/update-material.dto';

@Controller()
export class MaterialsController {
  constructor(private readonly service: MaterialsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_MATERIALS.GET_BY_COURSE })
  list(@Payload() filter: { courseId?: number }) {
    return this.service.getByCourse(filter);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_MATERIALS.GET_BY_ID })
  detail(@Payload() id: number) {
    return this.service.getById(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_MATERIALS.CREATE })
  create(@Payload() dto: any) {
    const { material, attachments } = dto;
    return this.service.create(material, attachments);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_MATERIALS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_MATERIALS.TRACK_VIEW })
  track(@Payload() payload: { id: number; student_id?: number }) {
    return this.service.trackView(payload.id, {
      student_id: payload.student_id,
    });
  }
}
