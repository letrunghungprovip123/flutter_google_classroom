import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { RMQ_PATTERN_SEMESTERS } from 'src/common/constants/rmq.pattern';
import { SemestersService } from './semesters.service';
import { CreateSemesterDto } from './dto/create-semester.dto';
import { UpdateSemesterDto } from './dto/update-semester.dto';

@Controller()
export class SemestersController {
  constructor(private readonly service: SemestersService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_SEMESTERS.LIST })
  list() {
    return this.service.list();
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SEMESTERS.GET })
  get(@Payload() id: number) {
    return this.service.get(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SEMESTERS.CREATE })
  create(@Payload() dto: CreateSemesterDto) {
    return this.service.create(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SEMESTERS.UPDATE })
  update(@Payload() payload: { id: number; data: UpdateSemesterDto }) {
    return this.service.update(+payload.id, payload.data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_SEMESTERS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(+id);
  }
}
