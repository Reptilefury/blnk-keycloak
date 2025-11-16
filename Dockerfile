# Simple Keycloak image with HTTPS reverse proxy support
FROM quay.io/keycloak/keycloak:23.0

# Set environment variables for HTTPS proxy support
ENV KC_PROXY=edge
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HEALTH_ENABLED=true
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak in standard mode (no optimization needed for now)
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
