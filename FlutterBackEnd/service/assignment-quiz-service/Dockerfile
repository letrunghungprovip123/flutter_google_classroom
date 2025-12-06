# =============================
# Builder stage
# =============================
FROM node:20-alpine AS builder
WORKDIR /app


RUN yarn config set registry https://registry.npmjs.org/

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

# Generate Prisma Client BEFORE build
RUN npx prisma generate

RUN yarn build

# =============================
# Runtime stage
# =============================
FROM node:20-alpine
WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Only install production deps
RUN yarn install --production

# Copy dist + prisma engine
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma

ENV PORT=3002
EXPOSE 3002

CMD ["node", "dist/main.js"]
