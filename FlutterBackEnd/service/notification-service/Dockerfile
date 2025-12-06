# =============================
# Builder
# =============================
FROM node:20-alpine AS builder
WORKDIR /app


RUN yarn config set registry https://registry.npmjs.org/

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS
RUN yarn build


# =============================
# Runtime
# =============================
FROM node:20-alpine
WORKDIR /app

COPY package.json yarn.lock ./

# Install only production dependencies
RUN yarn install --production

# Copy compiled files + prisma engine
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

# If you need Prisma schema for migrations:
COPY --from=builder /app/prisma ./prisma

ENV PORT=3003
EXPOSE 3003

CMD ["node", "dist/main.js"]
