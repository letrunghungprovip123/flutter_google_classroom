import { Module } from '@nestjs/common';
import { AnnoucementsService } from './annoucements.service';
import { AnnoucementsController } from './annoucements.controller';
import { PrismaModule } from 'src/prisma/prisma.module';
import { PrismaService } from 'src/prisma/prisma.service';
import { CloudinaryModule } from 'src/cloudinary/cloudinary.module';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { EmailModule } from 'src/email/email.module';
import { EmailService } from 'src/email/email.service';

@Module({
  imports: [PrismaModule, CloudinaryModule, EmailModule],
  controllers: [AnnoucementsController],
  providers: [
    AnnoucementsService,
    PrismaService,
    CloudinaryService,
    EmailService,
  ],
})
export class AnnoucementsModule {}
