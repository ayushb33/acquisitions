# Multi-stage Dockerfile for Node.js acquisitions application

# Base image with Node.js
FROM node:26-alpine AS base

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Set working directory & assign ownership
WORKDIR /app
RUN chown nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Copy package files with correct ownership
COPY --chown=nodejs:nodejs package*.json ./

# Install production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code with correct ownership
COPY --chown=nodejs:nodejs . .

# Expose the port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => { process.exit(1) })"

# Development stage
FROM base AS development
RUN npm ci && npm cache clean --force
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
CMD ["npm", "start"]