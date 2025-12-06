import { RpcException } from '@nestjs/microservices';

export function throwRpc(statusCode: number, message: string): never {
  throw new RpcException({ statusCode, message });
}

/**
 * Chuẩn hoá lỗi Prisma → RpcException(statusCode, message)
 * context: để log/tuỳ biến message nếu cần
 */
export function mapPrismaError(err: any, context?: string): never {
  // Unique constraint
  if (err?.code === 'P2002') {
    throwRpc(400, 'Dữ liệu trùng lặp (unique constraint)');
  }
  // Foreign key constraint
  if (err?.code === 'P2003') {
    throwRpc(400, 'Khoá ngoại không hợp lệ (foreign key constraint)');
  }
  // Record not found (update/delete)
  if (err?.code === 'P2025') {
    throwRpc(404, 'Bản ghi không tồn tại (record not found)');
  }
  // Fallback
  throwRpc(500, err?.message || `Lỗi hệ thống${context ? ': ' + context : ''}`);
}

/**
 * Tiện ích: assert điều kiện, vi phạm → 400
 */
export function assertOrBadRequest(cond: any, message: string): void {
  if (!cond) throwRpc(400, message);
}

/**
 * Tiện ích: assert tồn tại record, không có → 404
 */
export function assertFound(record: any, message = 'Không tìm thấy'): void {
  if (!record) throwRpc(404, message);
}
