# LibreChat Self-hosted Deploy

This directory contains the fork-owned self-hosted deployment bundle:

- `compose.yml`
- `Caddyfile`
- `deploy.env.example`
- `librechat.self-hosted.yaml`
- `generate-secrets.sh`
- `upload.sh`

## First Run

```sh
docker login registry.acceled.net
cp deploy.env.example .env
cp librechat.self-hosted.yaml librechat.yaml
docker compose -f compose.yml up -d
```

Replace every placeholder secret in `.env` before production use. Generate secrets with:

```sh
./generate-secrets.sh
```

For a private deployment, keep `ALLOW_REGISTRATION=true` for the first account,
then set it to `false` and restart:

```sh
docker compose -f compose.yml up -d
```

## Agent File Search

`librechat.self-hosted.yaml` enables Agent chat, file uploads, and Agent file search.
The compose stack includes the RAG API and pgvector database used by file search.

Set these values in `.env`:

```env
OPENAI_API_KEY=...
RAG_OPENAI_API_KEY=${OPENAI_API_KEY}
EMBEDDINGS_PROVIDER=openai
EMBEDDINGS_MODEL=text-embedding-3-small
```

Use `RAG_OPENAI_BASEURL` if embeddings should go through an OpenAI-compatible gateway.

## Domains

For production, set real DNS names that point to the deployment host:

```env
DOMAIN_CLIENT=https://chat.example.com
DOMAIN_SERVER=https://chat.example.com
LIBRECHAT_SITE_ADDRESS=https://chat.example.com
LIBRECHAT_ADMIN_ADDRESS=https://admin.example.com
ADMIN_PANEL_URL=https://admin.example.com
```

For local HTTP testing, use the localhost values commented in `deploy.env.example`
and set `SESSION_COOKIE_SECURE=false`.

## Upload to a Server

Upload the deployment bundle to an SSH target:

```sh
./upload.sh deploy@example.com
```

By default this uploads to `~/librechat-self-hosted` on the server. To choose a
directory:

```sh
./upload.sh deploy@example.com /opt/librechat
./upload.sh deploy@example.com:/opt/librechat
```

If local `.env` or `librechat.yaml` files exist in this directory, the script
uploads them too.
