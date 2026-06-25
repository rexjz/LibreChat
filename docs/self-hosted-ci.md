# Self-hosted CI

This fork keeps upstream workflow files unchanged where possible, so future syncs from
`upstream/main` have fewer conflicts. The fork-owned workflow lives in:

- `.github/workflows/self-hosted-ci.yml`

## What It Does

- Pull requests run validation only.
- Pushes to `main` run validation, then build and publish an amd64 API image.
- Manual `workflow_dispatch` runs validation. When dispatched from `main`, it also builds and
  publishes the image.
- No Docker Hub publishing is used.
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

The workflow uses `Dockerfile.multi` with target `api-build` and platform `linux/amd64`.

GitHub Container Registry packages may default to private visibility. If the deployment server
needs unauthenticated pulls, make the package public in GitHub Packages or configure registry
credentials on the server.

## Recommended GitHub Actions Cleanup

To minimize upstream merge conflicts, prefer disabling upstream-specific workflows in the
GitHub Actions UI instead of deleting or editing their YAML files. Good candidates to disable
in this fork include npm publishing, Docker Hub release publishing, DigitalOcean/Azure deploys,
Locize sync, Supabase embeddings, GitNexus, and Helm release workflows.
