import {
  Controller,
  Post,
  Put,
  Get,
  Param,
  Body,
  Inject,
  ParseIntPipe,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_QUIZ_ATTEMPTS } from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('quiz-attempts')
export class QuizAttemptsController {
  constructor(
    @Inject('ASSIGNMENT_SERVICE') private readonly client: ClientProxy,
  ) {}

  // POST /quiz-attempts

  @UseGuards(JwtAuthGuard)
  @Post()
  async start(@Body() dto: any, @Request() req: any) {
    try {
      const userId = req.user.id;
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.START },
          { userId, dto },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // PUT /quiz-attempts/:id/submit
  @Put(':id/submit')
  async submit(@Param('id', ParseIntPipe) id: number, @Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.SUBMIT },
          {
            attempt_id: id,
            answers: dto.answers,
          },
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // GET /quiz-attempts/:quizId
  @Get(':quizId')
  async getByQuiz(@Param('quizId', ParseIntPipe) quizId: number) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_QUIZ_ATTEMPTS.GET_BY_QUIZ },
          quizId,
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
