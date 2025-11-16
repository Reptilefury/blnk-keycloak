# Stage 1: Download the Socket Factory JAR and install curl for healthcheck
FROM registry.access.redhat.com/ubi9-minimal AS ubi-downloader

# Update and install curl and coreutils, allowing erasure of conflicting minimal packages
RUN microdnf update -y && \
    microdnf install -y --allowerasing curl coreutils && \
    microdnf clean all

# Download the JAR
RUN mkdir -p /opt/keycloak/providers && \
    curl -L -o /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar \
    https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar

# Stage 2: Build ubi-micro with curl for overlay in final image
FROM registry.access.redhat.com/ubi9:9.4 AS ubi-micro-build

RUN mkdir -p /mnt/rootfs

# Install minimal curl (libcurl-minimal to reduce size)
RUN dnf install --installroot /mnt/rootfs --releasever 9 --setopt install_weak_deps=false --nodocs -y curl libcurl-minimal ca-certificates && \
    dnf clean all --installroot /mnt/rootfs

# Stage 3: Keycloak builder with optimizations
FROM quay.io/keycloak/keycloak:23.0 AS builder

# Set build-time env for Postgres
ENV KC_DB=postgres

# Copy the downloaded JAR from downloader
COPY --from=ubi-downloader /opt/keycloak/providers /opt/keycloak/providers

# Chown and fix timestamps
RUN chown -R 1000:1000 /opt/keycloak/providers && \
    touch -m --date=@1743465600 /opt/keycloak/providers/*

# Build optimized distribution
RUN /opt/keycloak/bin/kc.sh build

# Stage 4: Runtime image
FROM quay.io/keycloak/keycloak:23.0

# Overlay curl from ubi-micro-build
COPY --from=ubi-micro-build /mnt/rootfs /

# Copy built artifacts from builder
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Set default environment variables for HTTPS proxy and admin
# These ensure Keycloak generates HTTPS URLs when behind a reverse proxy
ENV KC_PROXY=edge \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_HEALTH_ENABLED=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin123

# Health check (now with curl available)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak in optimized mode
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
