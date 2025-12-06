import { IsInt, IsString } from 'class-validator';

export class CreateGroupDto {
  @IsInt()
  course_id: number;

  @IsString()
  name: string;
}
