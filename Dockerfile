# Production Dockerfile for MyDrive Vault
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first for fast caching
COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/

RUN npm install

# Copy source code and build both frontend and backend
COPY . .
RUN npm run build

# Production runtime stage
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/

# Install only production dependencies
RUN npm install --omit=dev

# Copy compiled backend and frontend
COPY --from=builder /app/server/dist ./server/dist
COPY --from=builder /app/client/dist ./client/dist
COPY --from=builder /app/.env.example ./

# Create data directory for encrypted database
RUN mkdir -p /app/data

EXPOSE 5000

CMD ["node", "server/dist/index.js"]
