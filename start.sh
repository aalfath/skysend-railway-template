#!/bin/sh
# Railway start script for SkySend: checks the settings, starts SkySend on loopback and
# Caddy on $PORT in front of it, and exits non-zero as soon as either one stops, so
# Railway's ON_FAILURE restart policy brings the service back.
set -eu

log() { echo "[railway-start] $*"; }
die() { echo "[railway-start] ERROR: $*" >&2; exit 1; }

PUBLIC_PORT="${PORT:-8080}"
[ "$PUBLIC_PORT" = "3000" ] && die "PORT must not be 3000 (SkySend itself listens there on loopback)."

# The uploader side is locked by a generated password. Never start without a strong one.
UPLOAD_USERNAME="${UPLOAD_USERNAME:-skysend}"
UPLOAD_PASSWORD="${UPLOAD_PASSWORD:-}"
[ "${#UPLOAD_PASSWORD}" -ge 16 ] || die "UPLOAD_PASSWORD is empty or shorter than 16 characters. Set a long random value (the template generates one)."
case "$UPLOAD_USERNAME" in *[!A-Za-z0-9._@-]*|"") die "UPLOAD_USERNAME may only contain letters, digits, '.', '_', '-' and '@'." ;; esac

# BASE_URL goes into every share link. Fall back to the Railway domain when the reference
# resolved to nothing usable (for example plain "https://").
case "${BASE_URL:-}" in
  http://?*.?*|https://?*.?*) ;;
  *)
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
      log "BASE_URL '${BASE_URL:-}' is not a full URL; using https://${RAILWAY_PUBLIC_DOMAIN}"
      BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
    else
      log "BASE_URL is not set and the service has no public domain; using http://localhost:${PUBLIC_PORT}"
      BASE_URL="http://localhost:${PUBLIC_PORT}"
    fi ;;
esac
export BASE_URL

# Defaults that fit Railway's Free plan (0.5 GB volume). Every one can be overridden.
export FILE_MAX_SIZE="${FILE_MAX_SIZE:-100MB}"
export FILE_UPLOAD_QUOTA_BYTES="${FILE_UPLOAD_QUOTA_BYTES:-300MB}"
export FILE_DEFAULT_EXPIRE_SEC="${FILE_DEFAULT_EXPIRE_SEC:-86400}"
export NOTE_DEFAULT_EXPIRE_SEC="${NOTE_DEFAULT_EXPIRE_SEC:-86400}"

# All state on the one volume at /data.
export DATA_DIR=/data UPLOADS_DIR=/data/uploads BRANDING_DIR=/data/branding
mkdir -p /data/uploads /data/branding /data/db

# Hash the password for Caddy; the plain value never reaches Caddy's config or the logs.
UPLOAD_PASSWORD_HASH="$(caddy hash-password --plaintext "$UPLOAD_PASSWORD")" || die "could not hash UPLOAD_PASSWORD"
export UPLOAD_USERNAME UPLOAD_PASSWORD_HASH
export PORT="$PUBLIC_PORT"
caddy validate --config /etc/skysend/Caddyfile --adapter caddyfile >/tmp/caddy-validate.log 2>&1 \
  || { cat /tmp/caddy-validate.log >&2; die "Caddyfile is invalid"; }

# SkySend on loopback only; Caddy is the only way in.
( unset UPLOAD_PASSWORD UPLOAD_PASSWORD_HASH
  export HOST=127.0.0.1 PORT=3000 TRUST_PROXY=true TRUSTED_PROXIES=127.0.0.1/32,::1/128
  exec docker-entrypoint.sh node apps/server/dist/index.js ) &
APP_PID=$!

# Wait for SkySend before opening the public port.
i=0
until wget -q -O /dev/null http://127.0.0.1:3000/api/health 2>/dev/null; do
  kill -0 "$APP_PID" 2>/dev/null || { wait "$APP_PID" || true; die "SkySend exited during startup (see the lines above)."; }
  i=$((i + 1)); [ "$i" -lt 120 ] || die "SkySend did not answer /api/health within 120 s."
  sleep 1
done
log "SkySend is up; starting Caddy on port ${PUBLIC_PORT} (user '${UPLOAD_USERNAME}')"

( unset UPLOAD_PASSWORD
  exec su-exec skysend caddy run --config /etc/skysend/Caddyfile --adapter caddyfile ) &
PROXY_PID=$!

trap 'kill -TERM "$APP_PID" "$PROXY_PID" 2>/dev/null; exit 0' TERM INT

# BusyBox `wait -n` does not return on the first child exit, so poll both.
while kill -0 "$APP_PID" 2>/dev/null && kill -0 "$PROXY_PID" 2>/dev/null; do sleep 2; done
kill -0 "$APP_PID" 2>/dev/null && log "Caddy stopped" || log "SkySend stopped"
kill -TERM "$APP_PID" "$PROXY_PID" 2>/dev/null || true
exit 1
