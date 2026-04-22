# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CONTRIBUTING.md with contribution guidelines
- SECURITY.md with security policy and best practices
- CHANGELOG.md (this file)
- GitHub issue templates
- GitHub Actions badges in README

### Changed
- Registry references updated to `brandencobb/aws-vpn-client-saml`

## [1.0.0] - TBD

### Added
- Initial public release
- Docker container with AWS VPN Client + SAML auth support
- Multi-stage Dockerfile (patched OpenVPN 2.6.12)
- Go-based SAML response server
- Entrypoint script for automated auth flow
- Kubernetes deployment examples
- GitHub Actions workflow for automated Docker builds
- Release automation workflow
- Comprehensive README with architecture diagram
- MIT license

### Security
- `NET_ADMIN` capability requirement documented
- SAML token handling considerations documented
- DNS override behavior explained

[Unreleased]: https://github.com/BrandenCobb/aws-vpn-client-saml/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/BrandenCobb/aws-vpn-client-saml/releases/tag/v1.0.0
