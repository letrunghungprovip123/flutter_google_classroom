import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { AuthService } from './auth.service';
import { RMQ_PATTERN_AUTH, RMQ_PATTERN_INSTRUCTOR_DASHBOARD, RMQ_PATTERN_STUDENT } from 'src/common/constants/rmq.pattern';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Đăng ký tài khoản mới
   * cmd: signup_user
   */
  @MessagePattern({ cmd: RMQ_PATTERN_AUTH.SIGNUP })
  async signup(
    @Payload()
    data: {
      username: string;
      email: string;
      password: string;
      role?: string;
    },
  ) {
    return await this.authService.signup(data);
  }

  /**
   * Đăng nhập (trả JWT token)
   * cmd: login_user
   */
  @MessagePattern({ cmd: RMQ_PATTERN_AUTH.LOGIN })
  async login(@Payload() data: { username: string; password: string }) {
    return await this.authService.login(data);
  }

  /**
   * Lấy thông tin profile từ token
   * cmd: get_profile
   */
  @MessagePattern({ cmd: RMQ_PATTERN_AUTH.PROFILE })
  async profile(@Payload() token: string) {
    return await this.authService.profile(token);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_AUTH.UPDATE_PROFILE })
  async updateProfile(@Payload() data: any) {
    const { user_id, avatar, body } = data;
    return await this.authService.updateProfile(+user_id, avatar, body);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_AUTH.GET_DASHBOARD })
  async getDashboard(@Payload() data: any) {
    return await this.authService.getDashboard(+data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT.IMPORT_PREVIEW })
  async previewImport(@Payload() data: any) {
    return this.authService.previewCsv(data.rows);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT.IMPORT_CONFIRM })
  async confirmImport(@Payload() data: any) {
    return this.authService.bulkSignup(data.rows);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT.GET_ALL })
  async getAllStudents() {
    return this.authService.getAllStudents();
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENT.DELETE })
  async deleteStudent(@Payload() data: any) {
    return this.authService.deleteStudent(data.id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.GET_OVERVIEW })
  async getDashboardInstructor(
    @Payload() payload: { instructorId: number; semesterId?: number | null },
  ) {
    const { instructorId, semesterId } = payload;
    return this.authService.getDashboardInstructor(instructorId, semesterId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.GET_PROGRESS })
  async getDashboardProgress(@Payload() payload: any) {
    return this.authService.getDashboardProgress(payload);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_INSTRUCTOR_DASHBOARD.EXPORT_CSV })
  async exportCSV(@Payload() payload: any) {
    return this.authService.exportDashboardCSV(payload);
  }
}
