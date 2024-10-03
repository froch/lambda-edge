FROM node:lts-alpine AS builder
  WORKDIR /app
  COPY package.json pnpm-lock.yaml ./
  RUN npm install -g pnpm && pnpm install --frozen-lockfile
  COPY . .
  RUN pnpm run build
  CMD ["node", "dist/app.js"]

FROM public.ecr.aws/lambda/nodejs:12 AS lambda
    COPY --from=builder /app/dist /var/task
    CMD ["app.handler"]
