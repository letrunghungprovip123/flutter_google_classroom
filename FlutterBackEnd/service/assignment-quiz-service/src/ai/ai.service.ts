import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly model: any;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) throw new Error('GEMINI_API_KEY is not set');

    const genAI = new GoogleGenerativeAI(apiKey);
    // ✅ Model hợp lệ trong v1
    this.model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  }

  async generateSuggestion(body: any): Promise<string> {
    try {
    //   console.log(body);
      const prompt = `
Bạn là hệ thống AI chuyên tạo câu hỏi trắc nghiệm chuẩn giáo dục đại học.

Yêu cầu:
- Tạo câu hỏi theo chương trình học môn: "${body.subjectName}"
- Số câu yêu cầu:
  - Dễ: ${body.easyCount}
  - Trung bình: ${body.mediumCount}
  - Khó: ${body.hardCount}
- Mỗi câu có đúng 4 lựa chọn A/B/C/D
- Mỗi câu có đúng 1 đáp án đúng duy nhất
- Ngôn ngữ: Tiếng Việt, văn phong nghiêm túc, dễ hiểu
- Tuyệt đối KHÔNG thêm diễn giải đáp án hoặc ký tự ngoài JSON
- Không được viết lặp lại câu hỏi tương tự
- Không được xuống dòng trong chuỗi JSON Chỉ được sử dụng 1 dòng cho mỗi trường câu hỏi/đáp án

Định dạng JSON output DUY NHẤT:
[
  {
    "question_text": "...?",
    "option_a": "...",
    "option_b": "...",
    "option_c": "...",
    "option_d": "...",
    "correct_option": "a",
    "difficulty": "easy"
  }
]

⚠️ Lưu ý quan trọng:
- "difficulty" phải là một trong: "easy", "medium", "hard"
- "correct_option" phải là "a", "b", "c", hoặc "d"
- Output PHẢI là JSON hợp lệ 100% để system có thể parse trực tiếp
`;

      const result = await this.model.generateContent(prompt);
      console.log(result.response.text());
      return result.response.text();
    } catch (error) {
      this.logger.error('Lỗi khi gọi Gemini API:', error);
      return 'Xin lỗi, hiện tại tôi không thể gợi ý được 😢';
    }
  }
}
