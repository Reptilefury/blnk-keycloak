# Stage 1: Download Cloud SQL Socket Factory
FROM registry.access.redhat.com/ubi9-minimal AS downloader

# Install curl-minimal (to avoid package conflict on UBI minimal base)
RUN microdnf install -y curl-minimal && microdnf clean all

# Download the JAR and verify its existence. 
# Using 'set -e' and combining the steps ensures the build fails immediately on a download error, 
# preventing the "zip END header not found" issue.
RUN set -e && \
    mkdir -p /opt/keycloak/providers && \
    curl -L -o /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar \
    https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar && \
    test -s /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar

# Stage 2: Builder
FROM quay.io/keycloak/keycloak:23.0 AS builder

ENV KC_DB=postgres

COPY --from=downloader /opt/keycloak/providers /opt/keycloak/providers

# FIX: Temporarily switch to root to perform chown, then switch back to the default Keycloak user (1000).
# This resolves the "Operation not permitted" error.
USER root
RUN chown -R 1000:1000 /opt/keycloak/providers && \
    touch -m --date=@1743465600 /opt/keycloak/providers/*
USER 1000

RUN /opt/keycloak/bin/kc.sh build

# Stage 3: Runtime
FROM quay.io/keycloak/keycloak:23.0

COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENV KC_PROXY=edge \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_HEALTH_ENABLED=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin123

# Install curl-minimal for healthcheck (Requires root)
USER root
RUN microdnf install -y curl-minimal && microdnf clean all
USER 1000

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
