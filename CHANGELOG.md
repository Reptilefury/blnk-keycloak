# Changelog

All notable changes to the BLNK Keycloak project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-16

### Added
- Initial release of BLNK Keycloak with HTTPS proxy support
- Docker image based on Keycloak 23.0
- Proper environment variable defaults for reverse proxy deployments
- Environment variables to fix mixed content errors:
  - `KC_PROXY=edge` - Enables X-Forwarded-* header detection
  - `KC_HTTP_ENABLED=true` - Allows HTTP communication with proxy
  - `KC_HOSTNAME_STRICT=false` - Flexible hostname handling
  - `KC_HOSTNAME_STRICT_HTTPS=false` - No strict HTTPS enforcement
- GitHub Actions workflow for automatic building and pushing to Artifact Registry
- Multi-platform builds (linux/amd64 and linux/arm64)
- Docker Compose configuration for local development
- Comprehensive README with setup and deployment instructions
- Health check configuration

### Fixed
- ✅ Mixed content security errors when accessing behind reverse proxy (Cloud Run, APISIX, etc.)
- ✅ 3p-cookies iframe failures due to HTTP/HTTPS mismatch
- ✅ Admin UI not loading completely due to mixed content blocking
- ✅ OAuth flows broken when accessed through HTTPS proxy but Keycloak generating HTTP URLs

### Problem Background
When Keycloak was deployed to Cloud Run behind a reverse proxy:
1. Reverse proxy received HTTPS requests
2. Cloud Run load balancer terminated SSL and sent HTTP to container
3. Keycloak didn't properly detect HTTPS scheme from X-Forwarded-Proto header
4. Keycloak generated HTTP URLs in response
5. Browser blocked insecure HTTP resources loaded from HTTPS page
6. Admin console failed to load (3p-cookies iframe couldn't load over HTTP)

### Solution
This image includes environment variables that tell Keycloak to:
1. Trust X-Forwarded-Proto header from reverse proxy (`KC_PROXY=edge`)
2. Accept HTTP requests internally while proxy handles HTTPS
3. Generate HTTPS URLs based on the forwarded protocol

### Deployment
- Google Cloud Run compatible
- Free tier: 2Gi memory, 2 CPU recommended
- Works with Cloud SQL PostgreSQL
- Integrates with APISIX gateway for proper header forwarding

## Future Versions

### [1.1.0] - Planned
- [ ] Realm import automation
- [ ] Custom theme support
- [ ] Extended logging configuration
- [ ] OpenID Connect federation support

### [2.0.0] - Planned
- [ ] Upgrade to Keycloak 24.0+
- [ ] Support for custom providers
- [ ] Enhanced monitoring and metrics
- [ ] High availability configuration

---

## How to Interpret Changes

- **Added**: New features
- **Fixed**: Bug fixes
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Security**: Security-related fixes

## Upgrading

### From v1.0.0
No upgrades available yet. Current version is v1.0.0.

When v1.1.0 is released, simply tag the new version and push:
```bash
git tag -a v1.1.0 -m "Add realm import automation"
git push origin v1.1.0
```

GitHub Actions will automatically build and push the new image.
