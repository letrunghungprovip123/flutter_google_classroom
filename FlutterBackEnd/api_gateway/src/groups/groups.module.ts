import { Module } from '@nestjs/common';
import { GroupsService } from './groups.service';
import { GroupsController } from './groups.controller';
import { ClientsModule } from '@nestjs/microservices';
import { USER_SERVICE } from 'src/config/rabbmitmq-client.config';

@Module({
  imports: [ClientsModule.register([USER_SERVICE])],
  controllers: [GroupsController],
  providers: [GroupsService],
})
export class GroupsModule {}
