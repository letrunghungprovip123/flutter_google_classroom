import { IsInt, IsOptional, IsDateString } from 'class-validator';

export class CreateQuizAttemptDto {
  @IsInt()
  quiz_id: number;


  @IsOptional()
  @IsDateString()
  started_at?: string;
}
