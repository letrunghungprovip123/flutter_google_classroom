import { Module } from '@nestjs/common';
import { SemestersService } from './semesters.service';
import { SemestersController } from './semesters.controller';
import { ClientsModule } from '@nestjs/microservices';
import { USER_SERVICE } from 'src/config/rabbmitmq-client.config';

@Module({
  imports: [ClientsModule.register([USER_SERVICE])],
  controllers: [SemestersController],
  providers: [SemestersService],
})
export class SemestersModule {}
