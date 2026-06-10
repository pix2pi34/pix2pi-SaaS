FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod tidy
RUN go build -o app ./cmd/mission-control

FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/app .

EXPOSE 9001

CMD ["./app"]
