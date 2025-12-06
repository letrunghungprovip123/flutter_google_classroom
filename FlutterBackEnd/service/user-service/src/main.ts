import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
  const rmqUrl = 'amqp://flutter:1234@localhost:5672';
  console.log('🚀 USER SERVICE STARTING...');
  console.log('🔌 RabbitMQ URL =', rmqUrl);

  try {
    const app = await NestFactory.createMicroservice<MicroserviceOptions>(
      AppModule,
      {
        transport: Transport.RMQ,
        options: {
          urls: [rmqUrl],
          queue: 'user_queue',
          queueOptions: {
            durable: false,
          },
          noAck: false,
        },
      },
    );

    app
      .listen()
      .then(() => console.log('🟢 Connected to RabbitMQ successfully!'))
      .catch((err) =>
        console.error('❌ Failed to listen on RabbitMQ:', err.message),
      );

    console.log('⏳ Waiting for RabbitMQ connection...');
  } catch (err) {
    console.error('🔥 ERROR DURING BOOTSTRAP:', err);
  }
}

bootstrap();
