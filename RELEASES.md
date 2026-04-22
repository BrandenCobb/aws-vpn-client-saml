# Release Process

This project follows semantic versioning (MAJOR.MINOR.PATCH).

## Creating a Release

### 1. Tag the commit

```bash
# Example: v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0: Initial public release"
git push origin v1.0.0
```

### 2. Automated workflow

When you push a tag (`v*`), GitHub Actions will:
- Build and push the Docker image with multiple tags:
  - `brandencobb/aws-vpn-client-saml:1.0.0`
  - `brandencobb/aws-vpn-client-saml:1.0`
  - `brandencobb/aws-vpn-client-saml:latest`
  - `brandencobb/aws-vpn-client-saml:sha-<commit>`
- Create a GitHub Release with auto-generated release notes

### 3. Verify

- Docker Hub: https://hub.docker.com/r/brandencobb/aws-vpn-client-saml/tags
- GitHub Releases: https://github.com/BrandenCobb/aws-vpn-client-saml/releases

## Version Bumping Guidelines

- **MAJOR (x.0.0)**: Breaking changes (e.g., different entrypoint args, incompatible K8s config)
- **MINOR (1.x.0)**: New features, OpenVPN version bump, additional env vars
- **PATCH (1.0.x)**: Bug fixes, doc updates, security patches

## Example

```bash
# After merging bug fixes to master
git checkout master
git pull
git tag -a v1.0.1 -m "Fix DNS resolution timeout"
git push origin v1.0.1

# Watch the build
# https://github.com/BrandenCobb/aws-vpn-client-saml/actions
```
