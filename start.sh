#!/bin/sh
# Mika relay on Render: TLS is terminated by Render, so the relay runs
# behind it with -trust-proxy on $PORT, and its public origin is the
# service's own https://<name>.onrender.com address (RENDER_EXTERNAL_URL,
# which Render sets automatically; PUBLIC_URL can override it).
set -e

BIN="${MIKA_RELAY_BIN:-/app/mika-relay}"
DATA_DIR="${DATA_DIR:-/data}"
mkdir -p "$DATA_DIR"

# Owner key: if MIKA_OWNER_KEY is set in the environment (set it in the
# Render dashboard yourself, at least 32 characters), write it as the key
# file. Otherwise generate one on first boot inside the data dir.
if [ -n "$MIKA_OWNER_KEY" ]; then
  printf %s "$MIKA_OWNER_KEY" > "$DATA_DIR/owner-key"
  chmod 600 "$DATA_DIR/owner-key"
elif [ ! -s "$DATA_DIR/owner-key" ]; then
  "$BIN" -init-owner-key -owner-key-file "$DATA_DIR/owner-key"
fi

PUBLIC_URL="${PUBLIC_URL:-$RENDER_EXTERNAL_URL}"
if [ -z "$PUBLIC_URL" ]; then
  echo "PUBLIC_URL is not set and RENDER_EXTERNAL_URL is empty" >&2
  exit 1
fi

exec "$BIN" \
  -listen "0.0.0.0:${PORT:-8787}" \
  -public-url "$PUBLIC_URL" \
  -data "$DATA_DIR/relay.json" \
  -owner-key-file "$DATA_DIR/owner-key" \
  -trust-proxy
