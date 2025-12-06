import {
  IsInt,
  IsOptional,
  IsString,
  IsDateString,
  MaxLength,
  Min,
  IsNumber,
  IsNotEmpty,
} from 'class-validator';

export class CreateQuizDto {
  @IsInt()
  course_id: number;

  @IsInt()
  instructor_id: number;

  @IsString()
  @MaxLength(100)
  title: string;

  @IsOptional()
  @IsDateString()
  open_time?: string;

  @IsOptional()
  @IsDateString()
  close_time?: string;

  @IsOptional()
  @IsInt()
  duration_minutes?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  max_attempts?: number;

  @IsOptional()
  @IsInt()
  random_easy?: number;

  @IsOptional()
  @IsInt()
  random_medium?: number;

  @IsOptional()
  @IsInt()
  random_hard?: number;
}

export class CreateQuestionBankDto {
  @IsNumber()
  course_id: number;

  @IsString()
  @IsNotEmpty()
  question_text: string;

  @IsString()
  @IsNotEmpty()
  option_a: string;

  @IsString()
  @IsNotEmpty()
  option_b: string;

  @IsString()
  @IsNotEmpty()
  option_c: string;

  @IsString()
  @IsNotEmpty()
  option_d: string;

  @IsString()
  correct_option: string;

  @IsString()
  difficulty: string;
}