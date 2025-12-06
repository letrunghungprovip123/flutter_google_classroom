import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateMaterialDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  file_url?: string;
}
