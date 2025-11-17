# Multi-stage build to download Cloud SQL Socket Factory
FROM registry.access.redhat.com/ubi9-minimal as jar-downloader

RUN microdnf install -y curl && \
    mkdir -p /tmp/jars && \
    curl -L -o /tmp/jars/postgres-socket-factory.jar \
    https://repo1.maven.org/maven2/com/google/cloud/sql/postgres-socket-factory/1.27.0/postgres-socket-factory-1.27.0.jar && \
    microdnf clean all

# Keycloak image with HTTPS reverse proxy support and Cloud SQL integration
FROM quay.io/keycloak/keycloak:25.0.1

# Copy Cloud SQL Socket Factory JAR to providers directory
COPY --from=jar-downloader /tmp/jars/postgres-socket-factory.jar /opt/keycloak/providers/

# Build Keycloak with providers
RUN /opt/keycloak/bin/kc.sh build

# Set environment variables for reverse proxy and database support
ENV KC_PROXY=edge
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HEALTH_ENABLED=true
ENV KC_DB=postgres
ENV KC_CACHE=local
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
