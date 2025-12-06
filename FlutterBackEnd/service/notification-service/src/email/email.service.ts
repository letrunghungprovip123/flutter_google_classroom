import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter;

  constructor(private readonly configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true,
      auth: {
        user: this.configService.get<string>('EMAIL_USER'),
        pass: this.configService.get<string>('EMAIL_PASS'),
      },
    });
  }

  // ⛳ Common send function
  async send(to: string, subject: string, html: string) {
    await this.transporter.sendMail({
      from: `"TDTU Classroom" <${this.configService.get('EMAIL_USER')}>`,
      to,
      subject,
      html,
    });
  }

  // 📌 HTML UI Setup (global style wrapper)
  wrapHtml(title: string, content: string) {
    return `
      <div style="font-family:sans-serif;background:#f4f6f8;padding:20px">
        <div style="max-width:600px;margin:auto;background:white;border-radius:8px;padding:20px">
          <h2 style="color:#2B53FF">${title}</h2>
          <div style="font-size:15px;line-height:1.6;color:#333">
            ${content}
          </div>
          <hr style="margin-top:30px"/>
          <p style="font-size:12px;color:#888">Email tự động từ hệ thống TDTU Classroom — vui lòng không trả lời email này.</p>
        </div>
      </div>`;
  }

  // ======================
  // 1️⃣ ANNOUNCEMENT EMAIL
  // ======================
  async sendAnnouncement(
    to: string,
    course: string,
    title: string,
    content: string,
  ) {
    const body = `
      <p>Bạn có thông báo mới trong khoá học <strong>${course}</strong>.</p>
      <p><strong>${title}</strong></p>
      <div style="background:#f8f9fa;padding:12px;border-radius:8px">${content}</div>
      <p style="margin-top:20px"><a href="#" style="background:#2B53FF;color:white;padding:10px 20px;text-decoration:none;border-radius:6px">Xem tại Classroom</a></p>
    `;

    return this.send(
      to,
      `📢 Thông báo mới: ${title}`,
      this.wrapHtml('Thông báo mới', body),
    );
  }

  // ======================
  // 2️⃣ ASSIGNMENT DEADLINE REMINDER
  // ======================
  async sendAssignmentReminder(
    to: string,
    course: string,
    title: string,
    deadline: string,
  ) {
    const body = `
      <p>Hạn nộp bài tập đang đến gần trong <strong>${course}</strong>.</p>
      <p>Bài tập: <strong>${title}</strong></p>
      <p>⏳ Hạn cuối: <strong style="color:#E11D48">${deadline}</strong></p>
      <p style="margin-top:20px"><a href="#" style="background:#E11D48;color:white;padding:10px 20px;text-decoration:none;border-radius:6px">Nộp bài ngay</a></p>
    `;

    return this.send(
      to,
      `⏳ Sắp hết hạn: ${title}`,
      this.wrapHtml('Nhắc hạn bài tập', body),
    );
  }

  // ======================
  // 3️⃣ SUBMISSION SUCCESS EMAIL
  // ======================
  async sendAssignmentSubmit(
    to: string,
    course: string,
    title: string,
    submittedAt: string,
  ) {
    const body = `
      <p>Bạn đã nộp bài thành công cho <strong>${course}</strong>.</p>
      <p>Bài tập: <strong>${title}</strong></p>
      <p>📤 Thời gian nộp: <strong>${submittedAt}</strong></p>
    `;

    return this.send(
      to,
      `📤 Đã nộp bài: ${title}`,
      this.wrapHtml('Xác nhận nộp bài', body),
    );
  }

  // ======================
  // 4️⃣ GRADE RELEASE EMAIL
  // ======================
  async sendGraded(
    to: string,
    course: string,
    title: string,
    score: string,
    feedback: string,
  ) {
    const body = `
      <p>Đã có điểm cho bài tập trong <strong>${course}</strong>.</p>
      <p>Bài tập: <strong>${title}</strong></p>
      <p>Điểm: <strong style="color:#10B981;font-size:18px">${score}</strong></p>
      <p>Nhận xét:</p>
      <blockquote style="border-left:4px solid #2B53FF;padding-left:12px;color:#555">
        ${feedback}
      </blockquote>
      <p style="margin-top:20px"><a href="#" style="background:#10B981;color:white;padding:10px 20px;text-decoration:none;border-radius:6px">Xem bài đã chấm</a></p>
    `;

    return this.send(
      to,
      `📊 Đã chấm: ${title}`,
      this.wrapHtml('Kết quả bài tập', body),
    );
  }
}
