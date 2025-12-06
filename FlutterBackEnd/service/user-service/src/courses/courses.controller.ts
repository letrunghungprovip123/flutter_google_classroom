import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { RMQ_PATTERN_COURSES } from 'src/common/constants/rmq.pattern';
import { CoursesService } from './courses.service';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';

@Controller()
export class CoursesController {
  constructor(private readonly service: CoursesService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.LIST })
  list(@Payload() filter?: { semesterId?: number }) {
    return this.service.list(filter);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.GET })
  get(@Payload() id: number) {
    return this.service.get(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.CREATE })
  create(@Payload() data: any) {
    const { dto, instructor_id } = data;
    return this.service.create(+instructor_id, dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.UPDATE })
  update(@Payload() payload: { id: number; data: UpdateCourseDto }) {
    return this.service.update(+payload.id, payload.data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.GET_STUDENT_COURSE })
  studentCourse(@Payload() data: any) {
    const { user_id, semesterCode } = data;
    return this.service.studentCourse(+user_id, semesterCode);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_COURSES.GET_ALL_STUDENT })
  getAllStudents(@Payload() id: number) {
    return this.service.getAllStudents(+id);
  }
}
