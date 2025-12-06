import { Module } from '@nestjs/common';
import { SemestersService } from './semesters.service';
import { SemestersController } from './semesters.controller';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PrismaService } from 'src/prisma/prisma.service';

@Module({
  imports : [PrismaModule],
  controllers: [SemestersController],
  providers: [SemestersService,PrismaService],
})
export class SemestersModule {}
