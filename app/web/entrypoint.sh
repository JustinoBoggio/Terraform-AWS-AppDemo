#!/usr/bin/env sh
set -eu

# Generates config.js based on env vars
: "${APP_API_URL:=/api}"

cat >/usr/share/nginx/html/config.js <<EOF
window.__APP_CONFIG__ = {
  API_URL: "${APP_API_URL}"
};
EOF

# Arranca nginx
exec nginx -g "daemon off;"