[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/skysend?utm_medium=integration&utm_source=button&utm_campaign=skysend)

# SkySend on Railway

One-click [SkySend](https://github.com/Skyfay/SkySend) for Railway: end-to-end encrypted file and note sharing. Files and notes are encrypted in the browser, and the server only ever stores ciphertext.

## What this deploys

| Piece | What it does |
|---|---|
| SkySend v3.3.1 | Official image `skyfay/skysend:v3.3.1`, pinned by digest in the `Dockerfile`, listening on `127.0.0.1:3000` only |
| Caddy 2.11.9 | Public front on `$PORT`. Puts the uploader side behind a password and leaves links, downloads, notes and file-request uploads open to recipients |
| Volume `/data` | SQLite database (`/data/db`), encrypted uploads (`/data/uploads`), branding files (`/data/branding`) |

SkySend has no accounts of its own (only optional OIDC), so an open instance would let anyone on the internet store files on your volume. This template therefore puts creating uploads, notes and file requests behind HTTP basic auth with a generated password.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `UPLOAD_PASSWORD` | `${{secret(32)}}` | Password for the uploader side. Username is `UPLOAD_USERNAME`. The service refuses to start if it's shorter than 16 characters |
| `UPLOAD_USERNAME` | `skysend` | Username for the uploader side |
| `BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Used in every share link. Change it if you add a custom domain |
| `PORT` | `8080` | Port Caddy listens on (Railway's domain points here) |

Optional, read by the start script: `FILE_MAX_SIZE` (default `100MB`), `FILE_UPLOAD_QUOTA_BYTES` (default `300MB` per visitor per day), `FILE_DEFAULT_EXPIRE_SEC` and `NOTE_DEFAULT_EXPIRE_SEC` (default `86400`). Every other variable from [SkySend's reference](https://docs.skysend.app/user-guide/configuration/environment-variables) also works. The defaults fit Railway's Free plan (0.5 GB RAM, 0.5 GB volume). The service uses about 150 MB of RAM, including during a 95 MB upload.

## After deploying

Open the public URL and sign in with `skysend` and the `UPLOAD_PASSWORD` from the service's Variables tab. Share a file, a note or a file request, and send the link. Recipients don't need the password.

The health check is `/healthz`. If SkySend or Caddy stops, the container exits non-zero and Railway restarts it.

## Updates

New SkySend versions land here as a change to the `FROM` line in `Dockerfile`, with an entry in `CHANGELOG.md` (breaking changes first). Railway then shows an "update available" notice on projects deployed from this template, and you choose when to apply it. Your data stays on the volume.

## Licence

SkySend is AGPL-3.0 (Skyfay). The wrapper files in this repo are provided as-is.
