import { IsInt, IsOptional, IsString, IsArray } from 'class-validator';

export class CreateStudentDto {
  @IsString()
  student_code: string; // Mã sinh viên duy nhất

  @IsInt()
  user_id: number; // Khóa ngoại liên kết tới bảng users

  @IsOptional()
  @IsInt()
  year?: number; // Năm học

  @IsOptional()
  @IsArray()
  group_ids?: number[]; // Danh sách nhóm (nhiều-nhiều)
}
