#!/bin/sh
set -eu
mkdir -p /var/hedron/data
if [ ! -s /var/hedron/data/lattice.db ]; then
  if [ -s /var/hedron/seed/lattice.db ]; then
    cp /var/hedron/seed/lattice.db /var/hedron/data/lattice.db
  elif [ -f /app/seed/schema.sql ]; then
    sqlite3 /var/hedron/data/lattice.db < /app/seed/schema.sql
    sqlite3 /var/hedron/data/lattice.db < /app/seed/seed.sql
  fi
fi
exec python3 -m lab serve
