import { IsInt, IsString, MaxLength } from 'class-validator';

export class CreateAnnouncementDto {
  @IsInt()
  course_id: number;

  @IsInt()
  user_id: number;

  @IsString()
  @MaxLength(200)
  title: string;

  @IsString()
  content: string;
}

export class AttachmentDto {
  buffer: string; // base64 file
  originalname: string; // tên file gốc
  mimetype: string; // kiểu file (pdf, txt, html...)
  size: number; // dung lượng file
}