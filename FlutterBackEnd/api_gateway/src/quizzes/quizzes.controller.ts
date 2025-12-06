import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  Inject,
  ParseIntPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import {
  RMQ_PATTERN_QUESTION_BANK,
  RMQ_PATTERN_QUIZZES,
} from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('quizzes')
export class QuizzesController {
  constructor(
    @Inject('ASSIGNMENT_SERVICE') private readonly client: ClientProxy,
  ) {}

  @Get()
  async getAll(@Query('courseId') courseId?: string) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_QUIZZES.GET_ALL },
          courseId ? { courseId: +courseId } : {},
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUIZZES.CREATE }, dto),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Post('generate-ai')
  async generateAi(@Body() dto: any) {
    try {
      console.log(dto);
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUESTION_BANK.CREATE_AI }, dto),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Patch(':id')
  async update(@Param('id', ParseIntPipe) id: number, @Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUIZZES.UPDATE }, { id, dto }),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Delete(':id')
  async delete(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUIZZES.DELETE }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Post('question-bank')
  async createQuestions(@Body() dtos: any[]) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUESTION_BANK.CREATE }, dtos),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // ❌ Xóa câu hỏi
  @Delete('question-bank/:id')
  async deleteQuestion(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUESTION_BANK.DELETE }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // 📌 Lấy danh sách theo courseId
  @Get('question-bank')
  async getByCourse(@Query('courseId') courseId?: any) {
    console.log(courseId);
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_QUESTION_BANK.GET_ALL_BY_COURSE },
          Number(courseId),
        ),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  // 🔍 Lấy chi tiết
  @Get('question-bank/:id')
  async getQuestion(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUESTION_BANK.GET_BY_ID }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }

  @Get(':id')
  async getById(@Param('id', ParseIntPipe) id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_QUIZZES.GET_BY_ID }, id),
      );
    } catch (e) {
      throwHttpFromRpc(e);
    }
  }
}
