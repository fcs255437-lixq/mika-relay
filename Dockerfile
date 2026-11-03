# Mika self-hosted relay gateway, adapted for Render.
# Upstream deployment uses Docker Compose + Caddy on a host with its own
# domain; on Render the TLS certificate and HTTPS endpoint come from
# Render itself, so only the relay binary and a tiny start script run here.
FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
COPY web ./web
RUN go test ./... \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/mika-relay .

FROM alpine:3.20
RUN mkdir -p /app /data \
    && adduser -D -u 10001 relay \
    && chown 10001:10001 /data
COPY --from=build /out/mika-relay /app/mika-relay
COPY start.sh /app/start.sh
COPY LICENSE.coder-websocket.txt LICENSE NOTICE /licenses/
RUN chmod +x /app/start.sh
USER 10001:10001
VOLUME ["/data"]
EXPOSE 8787
ENTRYPOINT ["/app/start.sh"]
