import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { NotificationsService } from './notifications.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { UpdateNotificationDto } from './dto/update-notification.dto';
import { RMQ_PATTERN_NOTIFICATIONS } from 'src/common/constants/rmq.pattern';



@Controller()
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_NOTIFICATIONS.CREATE })
  create(@Payload() dto: CreateNotificationDto) {
    return this.service.create(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_NOTIFICATIONS.GET_BY_USER })
  getByUser(@Payload() id: number) {
    return this.service.getByStudent(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_NOTIFICATIONS.MARK_AS_READ })
  markAsRead(@Payload() id: number) {
    return this.service.markAsRead(id);
  }
}
