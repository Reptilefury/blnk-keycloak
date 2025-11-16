# Stage 1: Download Cloud SQL Socket Factory
FROM registry.access.redhat.com/ubi9-minimal AS downloader
# Define constants for file and checksum
ENV JAR_NAME=postgres-socket-factory-1.27.0.jar \
    JAR_URL=https://repo1.maven.org/maven2/com/google/cloud/sql/postgres-socket-factory/1.27.0/postgres-socket-factory-1.27.0.jar \
    SHA1_URL=https://repo1.maven.org/maven2/com/google/cloud/sql/postgres-socket-factory/1.27.0/postgres-socket-factory-1.27.0.jar.sha1 \
    PROVIDER_DIR=/opt/keycloak/providers
# Download the JAR and verify its integrity with SHA-1 checksum
RUN set -e && \
    mkdir -p ${PROVIDER_DIR} && \
    \
    # 1. Download the JAR and fail on error (-f)
    curl -f -L -o ${PROVIDER_DIR}/${JAR_NAME} ${JAR_URL} && \
    \
    # 2. Download the official SHA1 checksum file
    curl -f -L -o /tmp/expected.sha1 ${SHA1_URL} && \
    \
    # 3. Read the expected checksum
    EXPECTED_SHA1=$(cat /tmp/expected.sha1 | awk '{print $1}') && \
    \
    # 4. Calculate the actual checksum of the downloaded file
    ACTUAL_SHA1=$(sha1sum ${PROVIDER_DIR}/${JAR_NAME} | awk '{print $1}') && \
    \
    # 5. Compare the two checksums
    if [ "$EXPECTED_SHA1" != "$ACTUAL_SHA1" ]; then \
        echo "ERROR: SHA1 Checksum mismatch! Expected: $EXPECTED_SHA1, Actual: $ACTUAL_SHA1" >&2; \
        exit 1; \
    else \
        echo "SUCCESS: JAR file integrity verified." ; \
    fi

# Stage 2: Build ubi-micro with curl for overlay in final image
FROM registry.access.redhat.com/ubi9:9.4 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
# Install minimal curl (libcurl-minimal to reduce size), allowing erasure if needed
RUN dnf install --installroot /mnt/rootfs --releasever 9 --setopt install_weak_deps=false --nodocs -y --allowerasing curl-minimal libcurl-minimal ca-certificates && \
    dnf clean all --installroot /mnt/rootfs

# Stage 3: Builder
FROM quay.io/keycloak/keycloak:23.0 AS builder
ENV KC_DB=postgres
ENV PROVIDER_DIR=/opt/keycloak/providers
# Copy the verified JAR file
COPY --from=downloader ${PROVIDER_DIR} ${PROVIDER_DIR}
# FIX: Temporarily switch to root to perform chown, then switch back to the default Keycloak user (1000).
# This ensures the kc.sh build process has the correct permissions for the new file.
USER root
RUN chown -R 1000:1000 ${PROVIDER_DIR} && \
    touch -m --date=@1743465600 ${PROVIDER_DIR}/*
USER 1000
# This is the command that was failing due to the corrupted JAR file
RUN /opt/keycloak/bin/kc.sh build

# Stage 4: Runtime
FROM quay.io/keycloak/keycloak:23.0
# Overlay curl from ubi-micro-build
COPY --from=ubi-micro-build /mnt/rootfs /
COPY --from=builder /opt/keycloak/ /opt/keycloak/
# WARNING: Use Docker Secrets or ARG/ENV substitution in production for sensitive values like admin passwords!
# Set environment variables for HTTPS proxy support
ENV KC_PROXY=edge
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HEALTH_ENABLED=true
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin123ENV PORT=${PORT:-8080}
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:$PORT/health/ready || exit 1

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
