import { ClientProviderOptions, Transport } from '@nestjs/microservices';

export const USER_SERVICE: ClientProviderOptions = {
  name: 'USER_SERVICE',
  transport: Transport.RMQ,
  options: {
    urls: ['amqp://flutter:1234@rabbitmq:5672'],
    queue: 'user_queue',
    queueOptions: {
      durable: false,
    },
  },
};

export const ASSIGNMENT_SERVICE: ClientProviderOptions = {
  name: 'ASSIGNMENT_SERVICE',
  transport: Transport.RMQ,
  options: {
    urls: ['amqp://flutter:1234@rabbitmq:5672'],
    queue: 'assignment_queue',
    queueOptions: {
      durable: false,
    },
  },
};

export const NOTIFICATION_SERVICE: ClientProviderOptions = {
  name: 'NOTIFICATION_SERVICE',
  transport: Transport.RMQ,
  options: {
    urls: ['amqp://flutter:1234@rabbitmq:5672'],
    queue: 'notification_queue',
    queueOptions: {
      durable: false,
    },
  },
};
