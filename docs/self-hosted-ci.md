# Self-hosted CI

This fork keeps upstream workflow files unchanged where possible, so future syncs from
`upstream/main` have fewer conflicts. The fork-owned workflow lives in:

- `.github/workflows/self-hosted-ci.yml`
- `.github/workflows/self-hosted-support-images.yml`
- `deploy/self-hosted/compose.yml`

## What It Does

- Pull requests run validation only.
- Pushes to `main` run validation, then build and publish an amd64 API image.
- Manual `workflow_dispatch` runs validation. When dispatched from `main`, it also builds and
  publishes the image.
- No Docker Hub publishing is used. An optional extra container registry can be
  configured with repository variables and secrets.
- No server deployment, SSH, Azure, DigitalOcean, Locize, Supabase, GitNexus, or upstream release flow is used.

## Validation

The validation job runs:

- `npm ci`
- `npm run build:packages`
- `npm run build:client`

ESLint remains covered by the dedicated `ESLint Code Quality Checks` workflow,
which uses the project's changed-file linting logic. This workflow does not call
the root `npm run lint` script because that script's glob can fail in CI when
ESLint finds no matching files.

## Published Image

The image job publishes:

- `ghcr.io/<repository-owner>/librechat-api:<commit-sha>`
- `ghcr.io/<repository-owner>/librechat-api:main`

When `EXTRA_REGISTRY` is configured, the same image is also published to:

- `<EXTRA_REGISTRY>/<EXTRA_REGISTRY_NAMESPACE>/librechat-api:<commit-sha>`
- `<EXTRA_REGISTRY>/<EXTRA_REGISTRY_NAMESPACE>/librechat-api:main`

GHCR uses the standard Docker push path. The extra registry uses the bundled
`.ci/serverless-registry-push` chunked uploader so registries behind Cloudflare
request-size limits can accept large LibreChat image layers.

Configure the extra registry with:

- Repository variable `EXTRA_REGISTRY`, for example `registry.example.com`
- Repository variable `EXTRA_REGISTRY_NAMESPACE`, for example `team/max`
- Repository variable `EXTRA_REGISTRY_USERNAME`
- Repository secret `EXTRA_REGISTRY_PASSWORD`

If `EXTRA_REGISTRY_NAMESPACE` is not set, the workflow falls back to the lower-case
GitHub repository owner.

The workflow uses `Dockerfile.multi` with target `api-build` and platform `linux/amd64`.

GitHub Container Registry packages may default to private visibility. If the deployment server
needs unauthenticated pulls, make the package public in GitHub Packages or configure registry
credentials on the server.

## Self-hosted Compose

Use `deploy/self-hosted/compose.yml` for fork-owned deployments. The self-hosted
deployment files live together in `deploy/self-hosted/`:

- `compose.yml`
- `Caddyfile`
- `deploy.env.example`
- `librechat.self-hosted.yaml`
- `generate-secrets.sh`
- `README.md`
- `upload.sh`

Initial setup:

```sh
cd deploy/self-hosted
docker login registry.acceled.net
cp deploy.env.example .env
cp librechat.self-hosted.yaml librechat.yaml
docker compose -f compose.yml up -d
```

Replace every placeholder secret in `.env` before production use. Generate them with:

```sh
./generate-secrets.sh
```

The compose file defaults to:

- `registry.acceled.net/team/max/librechat-api:main`

Override the API image and tag with:

- `LIBRECHAT_API_IMAGE=<registry>/<namespace>/librechat-api`
- `LIBRECHAT_API_IMAGE_TAG=main`

The compose file keeps the same support services as the upstream deploy compose:
MongoDB, Meilisearch, pgvector, RAG API, admin panel, and Caddy.
Public dependency images default to the `registry.acceled.net/` mirror prefix to
speed up deployment pulls.

The bundled `librechat.self-hosted.yaml` enables Agent chat with file uploads and
Agent file search. It uses the local RAG API and pgvector services from the compose
stack. Configure `OPENAI_API_KEY` for chat and `RAG_OPENAI_API_KEY` for embeddings
in `.env`; by default `RAG_OPENAI_API_KEY` reuses `OPENAI_API_KEY`.

RAG API and admin panel are originally published under `registry.librechat.ai`.
Run the `Self-hosted Support Images` workflow when those images need to be mirrored
into `<EXTRA_REGISTRY>/<EXTRA_REGISTRY_NAMESPACE>` for self-hosted deployments.

Caddy defaults to `http://localhost` for the main app and `http://admin.localhost`
for the admin panel. For production, set:

- `LIBRECHAT_SITE_ADDRESS=example.com`
- `LIBRECHAT_ADMIN_ADDRESS=admin.example.com`

When those addresses are real public DNS names pointing at the deployment host,
Caddy can provision HTTPS automatically.

## Recommended GitHub Actions Cleanup

To minimize upstream merge conflicts, prefer disabling upstream-specific workflows in the
GitHub Actions UI instead of deleting or editing their YAML files. Good candidates to disable
in this fork include npm publishing, Docker Hub release publishing, DigitalOcean/Azure deploys,
Locize sync, Supabase embeddings, GitNexus, and Helm release workflows.
