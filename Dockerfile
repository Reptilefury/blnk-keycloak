# Stage 1: Download Cloud SQL Socket Factory JAR
FROM registry.access.redhat.com/ubi9 AS downloader

RUN microdnf update -y && microdnf clean all

RUN mkdir -p /opt/keycloak/providers && \
    curl -L -o /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar \
    https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar

# Stage 2: Keycloak builder with optimizations
FROM quay.io/keycloak/keycloak:23.0 AS builder

# Build-time env for Postgres
ENV KC_DB=postgres

# Copy Cloud SQL Socket Factory
COPY --from=downloader /opt/keycloak/providers /opt/keycloak/providers

# Fix permissions
RUN chown -R 1000:1000 /opt/keycloak/providers && \
    touch -m --date=@1743465600 /opt/keycloak/providers/*

# Build optimized Keycloak distribution
RUN /opt/keycloak/bin/kc.sh build

# Stage 3: Runtime image
FROM quay.io/keycloak/keycloak:23.0

# Copy optimized build and providers
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Default environment variables for HTTPS proxy and admin
ENV KC_PROXY=edge \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_HEALTH_ENABLED=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin123

# Install curl (needed for healthcheck)
USER root
RUN microdnf install -y curl && microdnf clean all
USER 1000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak in optimized mode
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
