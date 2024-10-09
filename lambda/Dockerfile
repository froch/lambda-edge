FROM node:lts-alpine AS builder
  WORKDIR /app

  COPY package.json pnpm-lock.yaml ./

  RUN set -eux; \
    npm install -g pnpm typescript; \
    pnpm nuke:prod

  COPY ./src/app.ts /app/src/app.ts
  COPY ./tsconfig.json /app/tsconfig.json
  COPY ./tsconfig.build.json /app/tsconfig.build.json

  RUN set -eux; \
    pnpm build

FROM public.ecr.aws/lambda/nodejs:20 AS app
  COPY --from=builder /app/dist /var/task
  CMD ["app.handler"]
