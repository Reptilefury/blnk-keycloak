# BLNK Keycloak - HTTPS-Enabled Identity Provider

Custom Keycloak Docker image with proper HTTPS proxy support for Cloud Run and other reverse proxy environments.

## Problem Solved

**Mixed Content Error**: When Keycloak is deployed behind a reverse proxy (Cloud Run, NGINX, APISIX), it was generating HTTP URLs instead of HTTPS URLs, causing:
- Mixed content security errors
- Admin UI not loading completely
- 3p-cookies iframe failures
- Broken OAuth flows

**Solution**: This image includes proper environment variables and configuration to ensure Keycloak generates HTTPS URLs when accessed through a reverse proxy.

## Key Features

- ✅ Proper HTTPS proxy detection (`KC_PROXY=edge`)
- ✅ HTTP allowed for internal communication with proxy
- ✅ Flexible hostname handling for Cloud Run and other platforms
- ✅ PostgreSQL database support
- ✅ Multi-platform builds (amd64 and arm64)
- ✅ Automatic Docker image builds and pushes via GitHub Actions
- ✅ Version tagging and release management

## Quick Start - Local Development

### Prerequisites
- Docker and Docker Compose
- PostgreSQL (or use the included docker-compose service)

### Run Locally

```bash
git clone https://github.com/Reptilefury/blnk-keycloak.git
cd blnk-keycloak

# Start with Docker Compose (includes PostgreSQL)
docker-compose up -d

# Access admin console
# HTTP:  http://localhost:8080
# Admin: admin / admin123

# Stop services
docker-compose down
```

## Docker Image

### Build Locally

```bash
docker build -t keycloak:latest .
```

### Push to Artifact Registry

The GitHub Actions workflow automatically builds and pushes on:
1. **Commits to main branch** → `latest` tag
2. **Git tags** (v1.0.0) → `1.0.0`, `1.0`, `1` tags
3. **Pull requests** → Built but not pushed (for testing)

### Manual Push

```bash
docker build -t us-central1-docker.pkg.dev/heroic-equinox-474616-i5/keycloak-repo/keycloak:v1.0.0 .
docker push us-central1-docker.pkg.dev/heroic-equinox-474616-i5/keycloak-repo/keycloak:v1.0.0
```

## Cloud Run Deployment

### Environment Variables

Set these when deploying to Cloud Run:

```bash
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://34.70.81.186:5432/keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=keycloak123
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin123
KC_PROXY=edge
KC_HTTP_ENABLED=true
KC_HOSTNAME_STRICT=false
KC_HOSTNAME_STRICT_HTTPS=false
```

### Deploy Command

```bash
gcloud run deploy keycloak \
  --image us-central1-docker.pkg.dev/heroic-equinox-474616-i5/keycloak-repo/keycloak:v1.0.0 \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --set-env-vars="KC_DB=postgres,KC_DB_URL=jdbc:postgresql://34.70.81.186:5432/keycloak,KC_DB_USERNAME=keycloak,KC_DB_PASSWORD=keycloak123"
```

## Accessing Keycloak

### Direct (not recommended - causes mixed content errors)
```
https://keycloak-438091062981.us-central1.run.app/admin/master/console/
```

### Via APISIX Gateway (recommended - properly forwards HTTPS)
```
https://136.111.45.49:19443/auth/admin/master/console/
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KC_PROXY` | `edge` | Proxy mode - tells Keycloak to trust X-Forwarded headers |
| `KC_HTTP_ENABLED` | `true` | Allow HTTP for internal proxy communication |
| `KC_HOSTNAME_STRICT` | `false` | Allow flexible hostname handling |
| `KC_HOSTNAME_STRICT_HTTPS` | `false` | Don't require HTTPS for hostname checks |
| `KC_DB` | `postgres` | Database type |
| `KC_DB_URL` | - | Database JDBC URL |
| `KC_DB_USERNAME` | `keycloak` | Database username |
| `KC_DB_PASSWORD` | `keycloak123` | Database password |
| `KEYCLOAK_ADMIN` | `admin` | Admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | `admin123` | Admin password |

## Version History

### v1.0.0 (Current)
- ✅ Initial release
- ✅ Fixed HTTPS proxy header detection
- ✅ Proper X-Forwarded-Proto handling
- ✅ Cloud Run compatible
- ✅ PostgreSQL database support
- ✅ Multi-platform builds (amd64, arm64)

## Dockerfile Overview

The Dockerfile:
1. Uses official Keycloak 23.0 image as base
2. Sets environment variables for HTTPS proxy support
3. Configures health check
4. Exposes ports 8080 (HTTP) and 8443 (HTTPS)

## Troubleshooting

### Keycloak not generating HTTPS URLs

**Symptom**: Still seeing HTTP URLs and mixed content errors

**Solution**:
1. Ensure reverse proxy sends `X-Forwarded-Proto: https` header
2. Verify `KC_PROXY=edge` environment variable is set
3. Check logs: `gcloud run logs read keycloak`

### Database connection errors

**Symptom**: "Failed to connect to database"

**Solution**:
1. Verify database is accessible from Cloud Run location
2. Check credentials in KC_DB_URL
3. Ensure PostgreSQL has keycloak user and database created

### Memory issues

**Symptom**: "Container ran out of memory"

**Solution**: Increase Cloud Run memory to 2Gi or more
```bash
gcloud run services update keycloak --memory 2Gi
```

## Building and Tagging Releases

### Create a release

```bash
# Tag the commit
git tag -a v1.0.1 -m "Fix HTTPS redirect issue"

# Push tag to GitHub (triggers build)
git push origin v1.0.1
```

The workflow will automatically:
1. Build the image with platform-specific builds
2. Tag as `1.0.1`, `1.0`, `1`, `latest`
3. Push to Artifact Registry

## License

This custom Keycloak configuration is part of the BLNK infrastructure project.

## References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Proxy Configuration](https://www.keycloak.org/server/all-config)
- [Cloud Run Configuration](https://cloud.google.com/run/docs)
