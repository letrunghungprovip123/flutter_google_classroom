// assignment-service/src/assignments/dto/create-assignment.dto.ts
import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateAssignmentDto {
  @IsInt()
  course_id: number;

  @IsInt()
  instructor_id: number;

  @IsString()
  @MaxLength(200)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsDateString()
  start_date?: string; // ISO

  @IsOptional()
  @IsDateString()
  deadline?: string; // ISO

  @IsOptional()
  @IsDateString()
  late_deadline?: string; // ISO

  @IsOptional()
  @IsBoolean()
  allow_late?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  max_attempts?: number;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  file_format?: string; // vd: "pdf,zip"

  @IsOptional()
  @IsInt()
  @Min(1)
  file_size_limit_mb?: number;
}

export class AttachmentDto {
  buffer: string; // base64 file
  originalname: string; // tên file gốc
  mimetype: string; // kiểu file (pdf, txt, html...)
  size: number; // dung lượng file
}