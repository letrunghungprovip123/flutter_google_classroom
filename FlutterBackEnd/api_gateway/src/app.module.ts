import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ClientsModule } from '@nestjs/microservices';
import {
  ASSIGNMENT_SERVICE,
  NOTIFICATION_SERVICE,
  USER_SERVICE,
} from './config/rabbmitmq-client.config';
import { SemestersModule } from './semesters/semesters.module';
import { CoursesModule } from './courses/courses.module';
import { GroupsModule } from './groups/groups.module';
import { StudentsModule } from './students/students.module';
import { AuthModule } from './auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { AssignmentsModule } from './assignments/assignments.module';
import { SubmissionsModule } from './submissions/submissions.module';
import { QuizzesModule } from './quizzes/quizzes.module';
import { QuizAttemptsModule } from './quiz_attempts/quiz_attempts.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AnnoucementsModule } from './annoucements/annoucements.module';
import { MaterialsModule } from './materials/materials.module';
import { EmailService } from './email/email.service';
import { EmailModule } from './email/email.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ClientsModule.register([
      USER_SERVICE,
      ASSIGNMENT_SERVICE,
      NOTIFICATION_SERVICE,
    ]),
    SemestersModule,
    CoursesModule,
    GroupsModule,
    StudentsModule,
    AuthModule,
    AssignmentsModule,
    SubmissionsModule,
    QuizzesModule,
    QuizAttemptsModule,
    NotificationsModule,
    AnnoucementsModule,
    MaterialsModule,
    EmailModule,
  ],
  controllers: [AppController],
  providers: [AppService, EmailService],
})
export class AppModule {}
