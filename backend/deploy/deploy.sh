#!/bin/sh
# Pull the latest pushed code for the API and dashboard onto the server and rebuild.
# Run from your Mac: sh backend/deploy/deploy.sh
set -e
ssh root@207.180.252.140 '
  cd /opt/ardy/repo && git pull -q &&
  cd /opt/ardy/dashboard && git pull -q &&
  cd /opt/ardy/repo/backend/deploy && docker compose up -d --build &&
  docker image prune -f >/dev/null
'
