import { IsInt, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateMaterialDto {
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
  @IsString()
  file_url?: string;
}

export class AttachmentDto {
  buffer: string; // base64 file
  originalname: string; // tên file gốc
  mimetype: string; // kiểu file (pdf, txt, html...)
  size: number; // dung lượng file
}
