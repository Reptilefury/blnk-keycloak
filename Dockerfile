# Keycloak with proper HTTPS proxy support and optimizations for Cloud SQL
FROM quay.io/keycloak/keycloak:23.0

# Set build-time env for Postgres
ENV KC_DB=postgres

# Install curl and add Cloud SQL Postgres Socket Factory JAR as a provider
RUN microdnf install -y curl && \
    mkdir -p /opt/keycloak/providers && \
    curl -L -o /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar \
    https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar && \
    chown 1000:1000 /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar && \
    touch -m --date=@1743465600 /opt/keycloak/providers/*  # Fix timestamp issue for optimized build && \
    microdnf clean all

# Build optimized distribution
RUN /opt/keycloak/bin/kc.sh build

# Set default environment variables for HTTPS proxy and admin
# These ensure Keycloak generates HTTPS URLs when behind a reverse proxy
ENV KC_PROXY=edge \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_HEALTH_ENABLED=true \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak in optimized mode
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
