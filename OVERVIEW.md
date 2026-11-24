# Deploy and Host SkySend on Railway

SkySend is a minimalist, self-hosted service for sharing files and notes with end-to-end encryption. Files and notes are encrypted in the sender's browser, and the key travels only in the link, so the server never sees the content. Links expire after a set time or number of downloads, and passwords are optional.

## About Hosting SkySend

This template runs the official SkySend v3.3.1 image, pinned by digest, in one service built from a public GitHub repo. SkySend has no user accounts, so a small Caddy proxy in the same container puts the uploader side (sharing files, creating notes and file requests) behind a generated password. Recipients open links, download files, read notes and send files into your requests without it. The SQLite database and the encrypted uploads live on one volume at `/data`. Defaults fit Railway's Free plan: 100 MB per file, 300 MB per visitor per day, links that expire after one day.

## Common Use Cases

* Send a large file or a folder to someone, with a link that expires after one download
* Share a password, API key or SSH key as a note that burns after reading
* Collect files from clients or colleagues through a file-request link, encrypted end to end

## Dependencies for SkySend Hosting

* One Railway service built from `aalfath/skysend-railway-template` (SkySend plus a Caddy front)
* One Railway volume at `/data` for the database and the encrypted uploads

### Deployment Dependencies

* SkySend: https://github.com/Skyfay/SkySend
* Documentation: https://docs.skysend.app

### Implementation Details

After the deploy, open the service's public URL. Your browser asks for a username and password: the username is `skysend` and the password is the `UPLOAD_PASSWORD` variable on the SkySend service (Variables tab). Only you need it. People you send links to never see the prompt.

Limits are optional variables on the service. Set them and redeploy:

* `FILE_MAX_SIZE` (default `100MB`) and `FILE_UPLOAD_QUOTA_BYTES` (default `300MB` per visitor per day). Raise them together with the volume size on paid plans.
* `FILE_DEFAULT_EXPIRE_SEC` and `NOTE_DEFAULT_EXPIRE_SEC` (default `86400`, one day).
* Any other setting from SkySend's environment variable reference, for example `CUSTOM_TITLE` or `ENABLED_SERVICES`.

The service uses about 150 MB of RAM and runs on the Free plan's 0.5 GB. It exits with an error if SkySend or Caddy stops, so Railway restarts it. Updates: new SkySend versions arrive as a change to the template repo, and Railway shows an "update available" notice on your project. Read `CHANGELOG.md` in the repo before you apply one.

## Why Deploy SkySend on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying SkySend on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
