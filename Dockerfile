# Keycloak image with HTTPS reverse proxy support and Cloud SQL integration
# Use ubi8/ubi:latest as a builder to download the Cloud SQL Socket Factory JAR
FROM registry.access.redhat.com/ubi8/ubi:latest as jar-builder

RUN yum install -y curl && \
    mkdir -p /tmp/jars && \
    curl -L -o /tmp/jars/cloud-sql-postgres-socket-factory.jar \
    https://repo1.maven.org/maven2/com/google/cloud/sql/cloud-sql-postgres-socket-factory/1.14.4/cloud-sql-postgres-socket-factory-1.14.4.jar && \
    yum clean all

# Start with Keycloak base image
FROM quay.io/keycloak/keycloak:23.0

# Copy the Cloud SQL Socket Factory JAR from builder
COPY --from=jar-builder /tmp/jars/cloud-sql-postgres-socket-factory.jar /opt/keycloak/lib/quarkus/

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

# Start Keycloak using environment variables for database configuration
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
