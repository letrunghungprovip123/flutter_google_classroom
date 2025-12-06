# =============================
# 🌐 API Gateway
# =============================
FROM node:20-alpine AS builder
WORKDIR /app

RUN yarn config set registry https://registry.npmjs.org/

# Copy package files
COPY package.json yarn.lock ./
RUN yarn install

# Copy code
COPY . .

# Build
RUN yarn build

# =============================
# Runtime
# =============================
FROM node:20-alpine
WORKDIR /app

# Copy dist + node_modules
COPY --from=builder /app ./

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "dist/main.js"]
