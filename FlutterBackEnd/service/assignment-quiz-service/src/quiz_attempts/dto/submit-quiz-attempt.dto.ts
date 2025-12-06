import { IsInt, IsNumber } from 'class-validator';

export class SubmitQuizAttemptDto {
  @IsInt()
  attempt_id: number;

  
  answers: {
    question_id: number;
    selected_option: 'a' | 'b' | 'c' | 'd';
  }[];
}
