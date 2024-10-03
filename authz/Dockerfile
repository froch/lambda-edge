FROM golang:1.23-alpine3.20 AS runner
  EXPOSE 8080

  WORKDIR /app
  COPY go.mod main.go ./
  RUN go build -o /app/authz
  CMD ["/app/authz"]

FROM alpine:3.20
  COPY --from=runner /app/authz /app/authz
  CMD ["/app/authz"]
