import {
  Body,
  Controller,
  Get,
  Post,
  Request,
  UseGuards,
  InternalServerErrorException,
  Inject,
  Patch,
  UseInterceptors,
  UploadedFiles,
  UploadedFile,
  Delete,
  Param,
  Query,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { JwtAuthGuard } from 'src/strategy/jwt-auth.guard';
import {
  RMQ_PATTERN_AUTH,
  RMQ_PATTERN_INSTRUCTOR_DASHBOARD,
  RMQ_PATTERN_STUDENT,
} from 'src/common/constants/rmq.pattern';
import { throwHttpFromRpc } from 'src/common/utils/rpc-error.util';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
@Controller('auth')
export class AuthController {
  constructor(
    @Inject('USER_SERVICE') private readonly userServiceClient: ClientProxy,
  ) {}

  @Post('signup')
  async signup(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.userServiceClient.send({ cmd: RMQ_PATTERN_AUTH.SIGNUP }, dto),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Post('login')
  async login(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.userServiceClient.send({ cmd: RMQ_PATTERN_AUTH.LOGIN }, dto),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Post('students/import/preview')
  async previewStudentImport(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_STUDENT.IMPORT_PREVIEW },
          dto,
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Post('students/import/confirm')
  async confirmStudentImport(@Body() dto: any) {
    try {
      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_STUDENT.IMPORT_CONFIRM },
          dto,
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Get('students')
  async getStudents() {
    try {
      return await lastValueFrom(
        this.userServiceClient.send({ cmd: RMQ_PATTERN_STUDENT.GET_ALL }, {}),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @Delete('students/:id')
  async deleteStudent(@Param('id') id: number) {
    try {
      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_STUDENT.DELETE },
          { id: Number(id) },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async profile(@Request() req) {
    try {
      // ✅ Lấy token gốc từ header
      const token = req.headers.authorization?.split(' ')[1];

      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_AUTH.PROFILE },
          token, // ✅ gửi chuỗi token thật
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Patch()
  @UseInterceptors(FileInterceptor('file'))
  async updateUser(
    @Request() req: any,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: any,
  ) {
    try {
      let avatar = null;

      if (file) {
        avatar = {
          buffer: file.buffer,
          originalname: file.originalname,
          mimetype: file.mimetype,
          size: file.size,
        };
      }
      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_AUTH.UPDATE_PROFILE },
          { user_id: req.user.id, avatar, body },
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('/instructor/dashboard/overview')
  async getDashboard(@Request() req, @Query('semesterId') semesterId?: string) {
    try {
      const instructorId = req.user.id; // admin/admin
      console.log(instructorId);

      const payload = {
        instructorId,
        semesterId: semesterId ? Number(semesterId) : null,
      };

      const res = await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.GET_OVERVIEW },
          payload,
        ),
      );
      return res;
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('/instructor/dashboard/progress')
  async getProgress(
    @Request() req,
    @Query('semesterId') semesterId?: string,
    @Query('courseId') courseId?: string,
    @Query('groupId') groupId?: string,
    @Query('status') status?: string,
    @Query('search') search?: string,
  ) {
    try {
      const instructorId = req.user.id;

      const payload = {
        instructorId,
        semesterId: semesterId ? Number(semesterId) : null,
        courseId: courseId ? Number(courseId) : null,
        groupId: groupId ? Number(groupId) : null,
        status,
        search,
      };

      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.GET_PROGRESS },
          payload,
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('/instructor/dashboard/export/csv')
  async exportDashboardCSV(
    @Request() req,
    @Query('semesterId') semesterId: string,
    @Query('type') type: string, // students | assignment | quiz | summary
  ) {
    try {
      const instructorId = req.user.id;

      const payload = {
        instructorId,
        semesterId: Number(semesterId),
        type,
      };

      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.EXPORT_CSV },
          payload,
        ),
      );
    } catch (err) {
      throwHttpFromRpc(err);
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('/dashboard')
  async getDashBoard(@Request() req: any) {
    try {
      const user_id = req.user.id;
      return await lastValueFrom(
        this.userServiceClient.send(
          { cmd: RMQ_PATTERN_AUTH.GET_DASHBOARD },
          user_id,
        ),
      );
    } catch (error) {
      throwHttpFromRpc(error);
    }
  }
}
