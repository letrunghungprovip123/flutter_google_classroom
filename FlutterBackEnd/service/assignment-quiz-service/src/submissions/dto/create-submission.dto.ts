// dto/create-submission.dto.ts
import { IsInt, IsOptional, IsString, MaxLength, IsUrl } from 'class-validator';

export class CreateSubmissionDto {
  @IsInt()
  assignment_id: number;

  @IsInt()
  student_id: number;

  file_url: string;
}


export class AttachmentDto {
  buffer: string; // base64 file buffer
  originalname: string;
  mimetype: string;
  size: number;
}
