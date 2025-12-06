import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { QuizzesService } from './quizzes.service';
import { RMQ_PATTERN_QUESTION_BANK, RMQ_PATTERN_QUIZZES } from 'src/common/constants/rmq.pattern';
import { CreateQuizDto } from './dto/create-quiz.dto';
import { UpdateQuizDto } from './dto/update-quiz.dto';

@Controller()
export class QuizzesController {
  constructor(private readonly quizzesService: QuizzesService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZZES.GET_ALL })
  getAll(@Payload() filter: { courseId?: number }) {
    return this.quizzesService.getAll(filter);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZZES.GET_BY_ID })
  getById(@Payload() id: number) {
    return this.quizzesService.getById(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZZES.CREATE })
  create(@Payload() dto: CreateQuizDto) {
    return this.quizzesService.create(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZZES.UPDATE })
  update(@Payload() payload: { id: number; dto: UpdateQuizDto }) {
    return this.quizzesService.update(payload.id, payload.dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUIZZES.DELETE })
  delete(@Payload() id: number) {
    return this.quizzesService.delete(id);
  }

  // =======================================
  // QUESTION BANK MessagePattern
  // =======================================
  @MessagePattern({ cmd: RMQ_PATTERN_QUESTION_BANK.CREATE })
  createQuestion(@Payload() dtos: any[]) {
    return this.quizzesService.createQuestion(dtos);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUESTION_BANK.DELETE })
  deleteQuestion(@Payload() id: number) {
    return this.quizzesService.deleteQuestion(id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUESTION_BANK.GET_ALL_BY_COURSE })
  getAllQuestion(@Payload() courseId: number) {
    return this.quizzesService.getAllQuestions(+courseId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_QUESTION_BANK.GET_BY_ID })
  getByIdQuestion(@Payload() id: number) {
    return this.quizzesService.getQuestionById(id);
  }
}
