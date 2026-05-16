# Generated from infra/docker/Dockerfile.go-service.template
# Build with: docker build --build-arg SERVICE_NAME=payment-service -f services/payment-service/Dockerfile -t payment-service:dev .
# syntax=docker/dockerfile:1.7

FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.work go.work.sum* ./
COPY services/payment-service/ services/payment-service/
COPY pkg/ pkg/
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    cd services/payment-service && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app ./cmd

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/app /app
USER 65532:65532
EXPOSE 8087
ENTRYPOINT ["/app"]
