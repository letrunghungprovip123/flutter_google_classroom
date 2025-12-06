import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateAnnoucementDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  content?: string;

  @IsOptional()
  @IsString()
  attachment_url?: string;
}
