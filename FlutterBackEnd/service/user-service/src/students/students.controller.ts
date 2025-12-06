import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import {
  RMQ_PATTERN_CHAT,
  RMQ_PATTERN_STUDENTS,
} from 'src/common/constants/rmq.pattern';
import { StudentsService } from './students.service';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';

@Controller()
export class StudentsController {
  constructor(private readonly service: StudentsService) {}

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.LIST })
  list(@Payload() filter: { groupId?: number }) {
    return this.service.list(filter);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.DETAIL })
  detail(@Payload() id: number) {
    return this.service.detail(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.CREATE })
  create(@Payload() dto: CreateStudentDto) {
    return this.service.create(dto);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.UPDATE })
  update(@Payload() payload: { id: number; data: UpdateStudentDto }) {
    return this.service.update(+payload.id, payload.data);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.DELETE })
  delete(@Payload() id: number) {
    return this.service.delete(+id);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_STUDENTS.IMPORT_CSV })
  importCsv(@Payload() payload: { rows: any[]; preview?: boolean }) {
    return this.service.importCsv(payload);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.GET_CONVERSATION })
  getConversation(@Payload() studentUserId: number) {
    return this.service.getConversation(+studentUserId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.LIST_CONVERSATIONS })
  listConversations() {
    // instructor id = 2 fix cứng trong service
    return this.service.listConversations();
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.CREATE_CONVERSATION })
  createConversation(@Payload() studentUserId: number) {
    return this.service.createConversation(+studentUserId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.GET_MESSAGES })
  getMessages(@Payload() conversationId: number) {
    return this.service.getMessages(+conversationId);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.SEND_MESSAGE })
  sendMessage(
    @Payload()
    body: {
      conversationId: number;
      senderId: number;
      content?: string;
      attachments?: {
        data: string; // base64 file data
        file_name: string;
        file_type: string;
        file_size: number;
      }[];
    },
  ) {
    return this.service.sendMessage(body);
  }

  @MessagePattern({ cmd: RMQ_PATTERN_CHAT.MARK_READ })
  markRead(
    @Payload()
    body: {
      conversationId: number;
      userId: number;
    },
  ) {
    return this.service.markRead(body.conversationId, body.userId);
  }
}
