# Keycloak image with HTTPS reverse proxy support and Cloud SQL integration
FROM quay.io/keycloak/keycloak:23.0

USER root

# Install curl and download Cloud SQL Socket Factory for PostgreSQL
RUN apk add --no-cache curl && \
    mkdir -p /opt/keycloak/lib/quarkus && \
    curl -L -o /opt/keycloak/lib/quarkus/cloud-sql-postgres-socket-factory.jar \
    https://repo1.maven.org/maven2/com/google/cloud/sql/cloud-sql-postgres-socket-factory/1.14.4/cloud-sql-postgres-socket-factory-1.14.4.jar && \
    apk del curl

USER 1000

# Set environment variables for reverse proxy and database support
ENV KC_PROXY=edge
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HEALTH_ENABLED=true
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin123
ENV KC_DB=postgres

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak using environment variables for database configuration
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
