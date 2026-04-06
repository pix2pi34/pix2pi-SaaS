FROM golang:1.24-alpine

WORKDIR /app

COPY . .

RUN go build -o plugin-erp cmd/plugin-erp/plugin_erp_main.go

EXPOSE 9002

CMD ["./plugin-erp"]
