FROM golang:1.23-alpine3.20 AS builder
  RUN apk add --no-cache \
      build-base \
      ca-certificates \
      linux-headers \
      binutils-gold \
      git

  WORKDIR /go/src/github.com/froch/lambda-edge/authz
  COPY go.mod go.sum ./
  RUN --mount=type=cache,target=/root/.cache/go-build \
      --mount=type=cache,target=/root/pkg/mod \
      set -eux; \
      go mod download

  COPY . .
  RUN --mount=type=cache,target=/root/.cache/go-build \
      --mount=type=cache,target=/root/pkg/mod \
      set -eux; \
	  go mod verify; \
	  go install -mod=readonly

FROM alpine:3.20 AS app
  EXPOSE 8080
  COPY --chmod=0777 --from=builder /go/bin/authz /usr/local/bin/authz
  CMD ["authz"]
