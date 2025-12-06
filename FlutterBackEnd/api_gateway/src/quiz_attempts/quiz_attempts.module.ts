import { Module } from '@nestjs/common';
import { QuizAttemptsService } from './quiz_attempts.service';
import { QuizAttemptsController } from './quiz_attempts.controller';
import { ClientsModule } from '@nestjs/microservices';
import { ASSIGNMENT_SERVICE } from 'src/config/rabbmitmq-client.config';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    ClientsModule.register([ASSIGNMENT_SERVICE]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET') || 'my_secret_key',
        signOptions: { expiresIn: '7d' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [QuizAttemptsController],
  providers: [QuizAttemptsService, JwtModule],
})
export class QuizAttemptsModule {}
