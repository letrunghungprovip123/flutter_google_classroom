import { Module } from '@nestjs/common';
import { QuizAttemptsService } from './quiz_attempts.service';
import { QuizAttemptsController } from './quiz_attempts.controller';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PrismaService } from 'src/prisma/prisma.service';

@Module({
  imports: [PrismaModule],
  controllers: [QuizAttemptsController],
  providers: [QuizAttemptsService, PrismaService],
})
export class QuizAttemptsModule {}
