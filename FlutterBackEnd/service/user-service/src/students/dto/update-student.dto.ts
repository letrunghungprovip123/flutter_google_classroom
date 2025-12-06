import { IsInt, IsOptional, IsString, IsArray } from 'class-validator';

export class UpdateStudentDto {
  @IsOptional()
  @IsString()
  student_code?: string;

  @IsOptional()
  @IsInt()
  user_id?: number;

  @IsOptional()
  @IsInt()
  year?: number;

  @IsOptional()
  @IsArray()
  group_ids?: number[];
}
