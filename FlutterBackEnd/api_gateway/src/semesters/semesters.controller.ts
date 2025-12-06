// api-gateway/src/modules/semesters/semesters.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Inject,
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  Patch,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { RMQ_PATTERN_SEMESTERS } from 'src/common/constants/rmq.pattern';

@Controller('semesters')
export class SemestersController {
  constructor(
    @Inject('USER_SERVICE') private readonly client: ClientProxy,
  ) {}

  @Get()
  async list() {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_SEMESTERS.LIST }, {}),
      );
    } catch (err) {
      throw new InternalServerErrorException(err.message);
    }
  }

  @Get(':id')
  async get(@Param('id') id: string) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_SEMESTERS.GET }, +id),
      );
    } catch (err: any) {
      if (err.statusCode === 404) throw new NotFoundException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }

  @Post()
  async create(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.client.send({ cmd: RMQ_PATTERN_SEMESTERS.CREATE }, dto),
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
          { cmd: RMQ_PATTERN_SEMESTERS.UPDATE },
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
        this.client.send({ cmd: RMQ_PATTERN_SEMESTERS.DELETE }, +id),
      );
    } catch (err: any) {
      if (err.statusCode === 404) throw new NotFoundException(err.message);
      throw new InternalServerErrorException(err.message);
    }
  }
}
