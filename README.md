# OpenCut container image

HelmForge packaging for the OpenCut web application.

This repository builds `docker.io/helmforge/opencut` from the upstream
`OpenCut-app/OpenCut` source tag and publishes signed multi-architecture images
with SBOMs.

## Tags

- `latest` tracks the configured upstream release.
- `vX.Y.Z` and `X.Y.Z` point to the same upstream OpenCut release.

## Build locally

```bash
docker build \
  --build-arg OPENCUT_VERSION=v0.3.0 \
  -t helmforge/opencut:v0.3.0 .

docker run --rm -p 3000:3000 helmforge/opencut:v0.3.0
```

## Runtime

The image runs as a non-root `opencut` user on port `3000`.

## Upstream

- Source: <https://github.com/OpenCut-app/OpenCut>
- License: MIT
