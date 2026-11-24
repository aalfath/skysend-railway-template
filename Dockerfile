# SkySend for Railway: the official image, pinned by version and digest, with a small Caddy
# front that puts the uploader side behind a generated password.
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM skyfay/skysend:v3.3.1@sha256:4859b30f003a8b7322a782da6cf726290b925d1988f33a3de3837c113d647c79

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/skysend/Caddyfile
COPY start.sh /usr/local/bin/railway-start.sh
RUN chmod 755 /usr/local/bin/railway-start.sh && caddy version

# Everything lives on the one Railway volume at /data. The upstream image bakes
# UPLOADS_DIR=/uploads, so it has to be set here explicitly.
ENV DATA_DIR=/data \
    UPLOADS_DIR=/data/uploads \
    BRANDING_DIR=/data/branding \
    TRUST_PROXY=true \
    PORT=8080

EXPOSE 8080
ENTRYPOINT []
CMD ["/usr/local/bin/railway-start.sh"]
