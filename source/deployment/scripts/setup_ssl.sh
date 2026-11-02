#!/bin/bash
set -euo pipefail

DOMAIN="salehvip-clud.ir"
SUBDOMAIN="reserve.salehvip-clud.ir"
EMAIL="admin@salehvip-clud.ir"

echo "Requesting Let's Encrypt SSL certificates for ${DOMAIN} and ${SUBDOMAIN}..."

# Obtain certificate using certbot standalone or webroot
certbot certonly --webroot \
  -w /var/www/certbot \
  -d ${DOMAIN} \
  -d ${SUBDOMAIN} \
  --email ${EMAIL} \
  --agree-tos \
  --no-eff-email \
  --force-renewal

echo "Certificates obtained successfully."
docker compose exec nginx nginx -s reload
