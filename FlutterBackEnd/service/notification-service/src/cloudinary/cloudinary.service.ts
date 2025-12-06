import { Inject, Injectable } from '@nestjs/common';
import { v2 as Cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  constructor(@Inject('CLOUDINARY') private cloudinary: typeof Cloudinary) {}

  uploadBuffer(
    buffer: Buffer,
    filename: string,
    mimetype: string,
  ): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const ext = filename.split('.').pop()?.toLowerCase(); // pdf, docx, txt...
      const nameWithoutExt = filename.replace(/\.[^/.]+$/, '');

      // Xác định resource_type chuẩn
      let resourceType: 'raw' | 'image' | 'video' = 'raw';
      if (mimetype.startsWith('image/')) resourceType = 'image';
      else if (mimetype.startsWith('video/')) resourceType = 'video';

      const uploadStream = this.cloudinary.uploader.upload_stream(
        {
          folder: 'classroom/announcements',
          resource_type: resourceType,
          public_id: `${Date.now()}-${nameWithoutExt}`, // KHÔNG có đuôi
          format: ext, // 🔥 ĐUÔI FILE NẰM Ở ĐÂY → URL CHẮC CHẮN CÓ ĐUÔI
          use_filename: true,
          unique_filename: false,
        },
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        },
      );

      streamifier.createReadStream(buffer).pipe(uploadStream);
    });
  }
}
