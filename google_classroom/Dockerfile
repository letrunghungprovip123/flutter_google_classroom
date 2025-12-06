# ================================
# Stage 1: Flutter Web Build
# ================================
FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build


# Tạo user
RUN groupadd -g 1001 fluttergroup \
    && useradd -m -u 1001 -g fluttergroup flutteruser

# 🔥 Fix quyền thư mục Flutter SDK
RUN chown -R flutteruser:fluttergroup /sdks/flutter

USER flutteruser
WORKDIR /app

# Fix Git ownership
RUN git config --global --add safe.directory /sdks/flutter

ENV CI=true

COPY --chown=flutteruser:fluttergroup . .

RUN flutter pub get
RUN flutter build web --release --web-renderer html --pwa-strategy=none
