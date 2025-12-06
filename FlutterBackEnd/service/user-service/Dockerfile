# ============================
# 👷 STAGE 1 — Builder
# ============================
FROM node:20-alpine AS builder
WORKDIR /app



RUN yarn config set registry https://registry.npmjs.org/

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies (include dev deps for build)
RUN yarn install

# Copy source code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS to dist
RUN yarn build

# ============================
# 🚀 STAGE 2 — Runtime
# ============================
FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

# Copy built code + node_modules + prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

EXPOSE 3001

CMD ["node", "dist/main.js"]
