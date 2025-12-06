import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Inject,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_NOTIFICATIONS } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('notifications')
export class NotificationsController {
  constructor(
    @Inject('NOTIFICATION_SERVICE') private readonly client: ClientProxy,
  ) {}

  @Post()
  async create(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_NOTIFICATIONS.CREATE }, dto),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('/student')
  async getByUser(@Request() req: any) {
    try {
      const studentId = req.user.id;
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_NOTIFICATIONS.GET_BY_USER },
          +studentId,
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Put(':id/read')
  async markAsRead(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_NOTIFICATIONS.MARK_AS_READ }, +id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
