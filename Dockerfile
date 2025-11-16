# Stage 1: Build optimized Keycloak with Postgres and socket factory
FROM quay.io/keycloak/keycloak:23.0 AS builder

# Set build-time env for Postgres
ENV KC_DB=postgres

# Add Cloud SQL Postgres Socket Factory JAR as a provider
RUN mkdir -p /opt/keycloak/providers
ADD --chown=keycloak:keycloak https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar /opt/keycloak/providers/

# Build optimized distribution
RUN /opt/keycloak/bin/kc.sh build

# Stage 2: Runtime image
FROM quay.io/keycloak/keycloak:23.0

# Copy built artifacts from builder
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Set runtime user
USER 1000

# Entry point for optimized start
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
