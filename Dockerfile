# Stage 1: Download Cloud SQL Socket Factory
FROM registry.access.redhat.com/ubi9-minimal AS downloader

# Install curl-minimal (required for the next step, minimal works in all arches)
RUN microdnf install -y curl-minimal && microdnf clean all

RUN mkdir -p /opt/keycloak/providers && \
    curl -L -o /opt/keycloak/providers/cloudsql-postgres-socket-factory-1.17.0.jar \
    https://repo1.maven.org/maven2/com/google/cloud/cloudsql-postgres-socket-factory/1.17.0/cloudsql-postgres-socket-factory-1.17.0.jar

# Stage 2: Builder
FROM quay.io/keycloak/keycloak:23.0 AS builder

ENV KC_DB=postgres

COPY --from=downloader /opt/keycloak/providers /opt/keycloak/providers
RUN chown -R 1000:1000 /opt/keycloak/providers && \
    touch -m --date=@1743465600 /opt/keycloak/providers/*

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

# Install curl-minimal for healthcheck
USER root
RUN microdnf install -y curl-minimal && microdnf clean all
USER 1000

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
