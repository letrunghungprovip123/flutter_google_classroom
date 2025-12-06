import { IsInt, IsOptional, IsString } from 'class-validator';

export class CreateCourseDto {
  @IsInt()
  semester_id: number;

  @IsString()
  code: string;

  @IsString()
  name: string;

  @IsInt()
  sessions: number; // số buổi học (vd: 15)

  @IsOptional()
  @IsInt()
  instructor_id?: number; // nếu có giảng viên gán sẵn
}
