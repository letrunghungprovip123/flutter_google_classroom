import {
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
  InternalServerErrorException,
  ForbiddenException,
} from '@nestjs/common';

export function throwHttpFromRpc(err: any): never {
  // ⚙️ Nếu Nest gói RpcException → lấy phần message bên trong
  const payload =
    typeof err?.message === 'object'
      ? err.message
      : typeof err?.response === 'object'
        ? err.response
        : err;

  const code = payload?.statusCode || payload?.status || err?.statusCode;
  const msg = payload?.message || err?.message || 'Internal error';
  switch (code) {
    case 400:
      throw new BadRequestException(msg);
    case 401:
      throw new UnauthorizedException(msg);
    case 403:
      throw new ForbiddenException(msg);
    case 404:
      throw new NotFoundException(msg);
    default:
      throw new InternalServerErrorException(msg);
  }
}
