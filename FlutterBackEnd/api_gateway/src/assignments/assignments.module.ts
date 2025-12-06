import { Module } from '@nestjs/common';
import { AssignmentsService } from './assignments.service';
import { AssignmentsController } from './assignments.controller';
import { Client, ClientsModule } from '@nestjs/microservices';
import { ASSIGNMENT_SERVICE } from 'src/config/rabbmitmq-client.config';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtStrategy } from 'src/strategy/jwt.strategy';

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
  controllers: [AssignmentsController],
  providers: [AssignmentsService, JwtStrategy],
})
export class AssignmentsModule {}
