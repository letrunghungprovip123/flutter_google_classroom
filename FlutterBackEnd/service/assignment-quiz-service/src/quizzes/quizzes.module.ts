import { Module } from '@nestjs/common';
import { QuizzesService } from './quizzes.service';
import { QuizzesController } from './quizzes.controller';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PrismaService } from 'src/prisma/prisma.service';
import { AiModule } from 'src/ai/ai.module';
import { AiService } from 'src/ai/ai.service';

@Module({
  imports: [PrismaModule, AiModule],
  controllers: [QuizzesController],
  providers: [QuizzesService, PrismaService, AiService],
})
export class QuizzesModule {}
