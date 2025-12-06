import { IsOptional, IsString } from 'class-validator';

export class CreateSemesterDto {
  @IsString()
  code: string;

  @IsString()
  name: string;

  @IsOptional()
  start_date?: string;

  @IsOptional()
  end_date?: string;
}
