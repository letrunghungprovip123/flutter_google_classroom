// assignment-service/src/assignments/dto/update-assignment.dto.ts
import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateAssignmentDto {
  @IsOptional()
  @IsInt()
  course_id?: number;

  @IsOptional()
  @IsInt()
  instructor_id?: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsDateString()
  start_date?: string;

  @IsOptional()
  @IsDateString()
  deadline?: string;

  @IsOptional()
  @IsDateString()
  late_deadline?: string;

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
  file_format?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  file_size_limit_mb?: number;
}
