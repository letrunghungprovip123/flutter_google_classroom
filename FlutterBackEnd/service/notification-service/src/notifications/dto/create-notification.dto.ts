import { IsInt, IsOptional, IsString } from 'class-validator';

export class CreateNotificationDto {
  @IsInt()
  student_id: number;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  message?: string;
}
