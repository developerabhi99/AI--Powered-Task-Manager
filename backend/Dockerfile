# Stage 1: Build TypeScript and Prisma client
FROM node:20-alpine AS builder

RUN apk add --no-cache openssl

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy Prisma schema and generate Prisma Client
COPY prisma ./prisma/
RUN npx prisma generate

# Copy source code and build TypeScript
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Stage 2: Production Image
FROM node:20-alpine AS runner

RUN apk add --no-cache openssl

WORKDIR /app

# Set env variables
ENV NODE_ENV=production

# Install only production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy generated Prisma Client from builder
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/prisma ./prisma

# Copy built code from builder
COPY --from=builder /app/dist ./dist

EXPOSE 5000

# Run db push to update database schema, then start the server
CMD ["sh", "-c", "npx prisma db push && npm start"]
