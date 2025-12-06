import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { PrismaModule } from './prisma/prisma.module';
import { AssignmentsModule } from './assignments/assignments.module';
import { SubmissionsModule } from './submissions/submissions.module';
import { QuizzesModule } from './quizzes/quizzes.module';
import { QuizAttemptsModule } from './quiz_attempts/quiz_attempts.module';
import { ConfigModule } from '@nestjs/config';
import { CloudinaryService } from './cloudinary/cloudinary.service';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { EmailService } from './email/email.service';
import { EmailModule } from './email/email.module';
import { AiModule } from './ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    PrismaModule,
    AssignmentsModule,
    SubmissionsModule,
    QuizzesModule,
    QuizAttemptsModule,
    CloudinaryModule,
    EmailModule,
    AiModule,
  ],
  controllers: [AppController],
  providers: [AppService, PrismaService, CloudinaryService, EmailService],
})
export class AppModule {}
