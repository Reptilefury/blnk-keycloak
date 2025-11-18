# Keycloak image with HTTPS reverse proxy support and Supabase PostgreSQL integration
FROM quay.io/keycloak/keycloak:25.0.1

# Set environment variables for reverse proxy and database support
# Note: KC_DB_URL will be set at runtime via Cloud Run environment variables
ENV KC_PROXY=edge
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HEALTH_ENABLED=true
ENV KC_DB=postgres
ENV KC_CACHE=local
ENV KEYCLOAK_ADMIN=reptilefury
ENV KEYCLOAK_ADMIN_PASSWORD=10325Fil

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=10 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

# Start Keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start"]
