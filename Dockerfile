FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends sqlite3 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir duckdb

WORKDIR /app
COPY lab/ /app/lab/
COPY seed/ /app/seed/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && printf '%s\n' '#!/bin/sh' 'exec python3 -m lab "$@"' > /usr/local/bin/lab \
    && chmod +x /usr/local/bin/lab

ENV PYTHONPATH=/app
ENV LESSONS_FEED=https://hedronite.com
ENV LATTICE_DB=/var/hedron/data/lattice.db
ENV LAB_BIND=0.0.0.0
ENV LAB_PORT=18800

EXPOSE 18800
ENTRYPOINT ["docker-entrypoint.sh"]
