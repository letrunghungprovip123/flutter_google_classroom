import { Inject, Injectable, BadRequestException } from '@nestjs/common';
import { v2 as Cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  constructor(@Inject('CLOUDINARY') private cloudinary: typeof Cloudinary) {}

  /**
   * Upload đa năng cho mọi loại file (ảnh, pdf, video...)
   * @param buffer - file buffer
   * @param filename - tên file gốc
   * @param mimetype - loại file
   * @param folder - thư mục cloudinary (vd: 'classroom/materials')
   */
  uploadFile(
    buffer: Buffer,
    filename: string,
    mimetype: string,
  ): Promise<UploadApiResponse> {
    if (!buffer) {
      throw new BadRequestException('Không có file để upload');
    }

    return new Promise((resolve, reject) => {
      const uploadStream = this.cloudinary.uploader.upload_stream(
        {
          folder: 'classroom/materials',
          resource_type: 'auto', // 🔥 TỰ NHẬN FILE LOẠI GÌ CŨNG ĐƯỢC
          use_filename: true,
          unique_filename: true,
          overwrite: false,
        },
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        },
      );

      streamifier.createReadStream(buffer).pipe(uploadStream);
    });
  }

  /**
   * Upload avatar chỉ cho phép image
   */
  uploadAvatar(
    buffer: Buffer,
    filename: string,
    mimetype: string,
  ): Promise<UploadApiResponse> {
    if (!mimetype.startsWith('image/')) {
      throw new BadRequestException('Avatar phải là hình ảnh');
    }

    return new Promise((resolve, reject) => {
      const uploadStream = this.cloudinary.uploader.upload_stream(
        {
          folder: 'classroom/avatars',
          resource_type: 'image',
          use_filename: true,
          unique_filename: true,
          overwrite: true,
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
