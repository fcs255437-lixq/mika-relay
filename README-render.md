# Mika relay gateway — Render deployment bundle

Source: wangzan101/Mika `tools/relay` (v0.1.34 era), with only the packaging
adapted for Render. The relay code itself is unmodified.

Why a custom Dockerfile/start.sh: upstream deploys with Docker Compose +
Caddy on a host with its own domain and persistent volumes. On Render, TLS
and the public HTTPS address come from Render, and free instances have no
persistent disk, so:

- `start.sh` runs the relay on `0.0.0.0:$PORT` with `-trust-proxy`.
- The public origin is `RENDER_EXTERNAL_URL` (Render sets it automatically);
  `PUBLIC_URL` can override it.
- The gateway validates the Host header against the public origin
  (requests with a wrong Host get `{"error":"invalid_host"}`).
- Owner key: set env var `MIKA_OWNER_KEY` (at least 32 characters, invented
  by the service owner and entered directly in the Render dashboard) and
  start.sh writes it to the key file on every boot. If the env var is
  absent, a key is generated on first boot inside /data — on Render that
  key is then unreadable from outside and lost on restart, so for Render
  always set `MIKA_OWNER_KEY`.
- Pairing state (/data/relay.json) is still on the ephemeral filesystem:
  a redeploy or instance replacement loses the pairing and the phone must
  be paired again. The owner key survives because it comes from the env var.

## Steps

1. Put this bundle at the root of a GitHub repository the (new) Render
   account can access, e.g. a new repo `mika-relay`.
2. Render dashboard (new account): New → Web Service → connect that repo.
   - Environment: Docker
   - Region: Oregon (same as the existing cliproxyapi service)
   - Instance type: Free
   - Health Check Path: `/healthz`
3. Environment variable (enter it yourself in the dashboard, never in chat):
   - `MIKA_OWNER_KEY` = a random secret of at least 32 characters
   No other env vars are needed.
4. Create the service and watch the deploy log until it is Live.
5. Verify from outside: `GET https://<service>.onrender.com/healthz`
   returns `{"status":"ok"}`.
6. Pairing (owner, on the phone):
   - Open the gateway URL in a browser, enter the owner key, create a
     pairing code (valid 5 minutes, single use).
   - On the phone in Mika: Settings → Connect a computer → Remote, enter
     the gateway origin `https://<service>.onrender.com` and the code,
     tap Pair gateway, then explicitly turn on "Allow remote access".
   - Copy the phone access token shown under CLI / Skill → Remote into a
     private token file on the computer that will run the CLI.
7. Computer side check:
   `mika connect --url https://<service>.onrender.com --token-file <file>`
   then `mika --url ... --token-file ... doctor`.

## Local smoke test (already done on 2026-11-03)

With PORT, RENDER_EXTERNAL_URL and a dummy MIKA_OWNER_KEY set, start.sh
booted the relay; `/healthz` returned `{"status":"ok"}` and the Web UI
returned 200 when the request carried the matching Host header.
The Docker build itself could not be tested on the build VM (no Docker);
the Dockerfile's build stage mirrors upstream's (go test, then build),
so the first full build test is the Render deploy itself.
