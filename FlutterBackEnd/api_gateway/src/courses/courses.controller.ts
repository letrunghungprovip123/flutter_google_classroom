// api-gateway/src/modules/courses/courses.controller.ts
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
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  Patch,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_COURSES } from 'src/common/constants/rmq.pattern';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';

@Controller('courses')
export class CoursesController {
  constructor(@Inject('USER_SERVICE') private readonly client: ClientProxy) {}

  @Get()
  async list(@Query('semesterId') semesterId?: string) {
    try {
      // console.log(semesterId);
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COURSES.LIST },
          semesterId ? { semesterId: +semesterId } : {},
        ),
      );
    } catch (err) {
      throw new InternalServerErrorException(err.message);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('student-courses')
  async studentCourse(
    @Request() req: any,
    @Query('semesterCode') semesterCode: string,
  ) {
    try {
      console.log(semesterCode);
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COURSES.GET_STUDENT_COURSE },

          { user_id: req.user.id, semesterCode },
        ),
      );
    } catch (err) {
      throw new InternalServerErrorException(err.message);
    }
  }

  @Get('all-student/:id')
  async getAllStudentsCourse(@Param('id') id: number) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_COURSES.GET_ALL_STUDENT }, id),
      );
    } catch (err) {
      throw new InternalServerErrorException(err.message);
    }
  }

  @Get(':id')
  async get(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_COURSES.GET }, +id),
      );
    } catch (err: any) {
      if (err.statusCode === 404) throw new NotFoundException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Body() dto: any, @Request() req: any) {
    try {
      const instructor_id = req.user.id;
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COURSES.CREATE },
          { dto, instructor_id },
        ),
      );
    } catch (err: any) {
      if (err.statusCode === 400) throw new BadRequestException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send(
          { cmd: RMQ_PATTERN_COURSES.UPDATE },
          { id: +id, data: dto },
        ),
      );
    } catch (err: any) {
      if (err.statusCode === 404) throw new NotFoundException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_COURSES.DELETE }, +id),
      );
    } catch (err: any) {
      if (err.statusCode === 404) throw new NotFoundException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }
}
