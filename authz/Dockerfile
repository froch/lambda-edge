FROM golang:1.23-alpine3.20 AS builder
  WORKDIR /app
  COPY go.mod go.sum main.go ./
  RUN set -eux; \
    apk add --no-cache git; \
    go mod download; \
    go build -mod=readonly -o /app/authz
  CMD ["/app/authz"]

FROM alpine:3.20 AS app
  EXPOSE 8080
  COPY --chmod=0777 --from=builder /app/authz /app/authz
  CMD ["/app/authz"]
