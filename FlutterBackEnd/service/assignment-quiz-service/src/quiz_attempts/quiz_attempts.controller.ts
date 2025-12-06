import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { RMQ_PATTERN_QUIZ_ATTEMPTS } from 'src/common/constants/rmq.pattern';
import { QuizAttemptsService } from './quiz_attempts.service';
import { CreateQuizAttemptDto } from './dto/create-quiz_attempt.dto';
import { SubmitQuizAttemptDto } from './dto/submit-quiz-attempt.dto';

@Controller()
export class QuizAttemptsController {
  constructor(private readonly service: QuizAttemptsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.START })
  start(@Payload() data: any) {
    const {userId,dto} = data
    return this.service.startAttempt(+userId,dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.SUBMIT })
  submit(@Payload() dto: SubmitQuizAttemptDto) {
    return this.service.submit(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.GET_BY_QUIZ })
  getByQuiz(@Payload() quizId: number) {
    return this.service.getByQuiz(quizId);
  }
}
