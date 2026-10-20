#!/bin/sh
# Daily backup of the openGym data volume (users, passkeys, workout state, session secret).
# The archive contains secrets — keep BACKUP_DIR outside the repo and private.
# Restore: docker compose down && docker run --rm -v opengym_opengym_data:/data -v "$BACKUP_DIR":/b alpine \
#            sh -c 'rm -rf /data/* && tar xzf /b/<file>.tgz -C /data' && docker compose up -d
set -eu

VOLUME="${VOLUME:-opengym_opengym_data}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/opengym}"
KEEP_DAYS="${KEEP_DAYS:-14}"

umask 077
mkdir -p "$BACKUP_DIR"
file="opengym-$(date +%F_%H%M).tgz"

# Runs as root to read the 0600 secret files; hand the archive back to the caller afterwards.
docker run --rm -v "$VOLUME":/data:ro -v "$BACKUP_DIR":/b alpine \
  sh -c "tar czf /b/$file.tmp -C /data . && chown $(id -u):$(id -g) /b/$file.tmp && chmod 600 /b/$file.tmp"
mv "$BACKUP_DIR/$file.tmp" "$BACKUP_DIR/$file"

# Refuse to prune if the new archive is not readable, so a broken backup never eats the old ones.
tar tzf "$BACKUP_DIR/$file" >/dev/null
find "$BACKUP_DIR" -name 'opengym-*.tgz' -mtime +"$KEEP_DAYS" -delete

echo "ok: $BACKUP_DIR/$file"
