# Keycloak with proper HTTPS proxy support
FROM quay.io/keycloak/keycloak:23.0

# Set default environment variables for HTTPS proxy
# These ensure Keycloak generates HTTPS URLs when behind a reverse proxy
ENV KC_PROXY=edge \
    KC_HTTP_ENABLED=true \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=admin123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
