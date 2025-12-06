// dto/grade-submission.dto.ts
import { IsDecimal, IsInt, Max, Min } from 'class-validator';

export class GradeSubmissionDto {
  @IsInt()
  submission_id: number;

  @IsDecimal()
  @Min(0)
  @Max(10)
  grade: number;
}
