FROM golang:1.23-alpine3.20 AS builder
  WORKDIR /app
  COPY go.mod main.go ./
  RUN go build -o /app/authz
  CMD ["/app/authz"]

FROM alpine:3.20 AS app
  EXPOSE 8080
  COPY --chmod=0777 --from=builder /app/authz /app/authz
  CMD ["/app/authz"]
