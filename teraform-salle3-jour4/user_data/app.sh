#!/bin/bash
set -euxo pipefail

# Tier application : API Python Flask exposee sur le port applicatif.
# L'API parle uniquement au PostgreSQL du tier donnees.
dnf install -y python3 python3-pip postgresql15

mkdir -p /opt/nordcloud-api
python3 -m venv /opt/nordcloud-api/venv
/opt/nordcloud-api/venv/bin/pip install --upgrade pip
/opt/nordcloud-api/venv/bin/pip install flask gunicorn psycopg2-binary

cat >/opt/nordcloud-api/app.py <<'PY'
import os
import time
import base64
from datetime import datetime, timezone

import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request

app = Flask(__name__)

DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "port": int(os.environ["DB_PORT"]),
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": base64.b64decode(os.environ["DB_PASSWORD_B64"]).decode("utf-8"),
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def init_db():
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id SERIAL PRIMARY KEY,
                    message TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                """
            )
            cursor.execute(
                """
                INSERT INTO messages (message)
                SELECT %s
                WHERE NOT EXISTS (SELECT 1 FROM messages);
                """,
                ("NordCloud API connected to PostgreSQL",),
            )


def wait_for_db():
    last_error = None
    for _ in range(60):
        try:
            init_db()
            return
        except Exception as exc:
            last_error = exc
            time.sleep(5)
    raise RuntimeError(f"Database unavailable after bootstrap retries: {last_error}")


@app.get("/")
def index():
    return jsonify(
        service="nordcloud-api",
        environment=os.environ.get("APP_ENV", "unknown"),
        database_host=DB_CONFIG["host"],
    )


@app.get("/health")
def health():
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1;")
        return jsonify(status="ok", tier="application", database="ok")
    except Exception as exc:
        return jsonify(status="degraded", tier="application", database="error", detail=str(exc)), 503


@app.get("/api/v1/messages")
def list_messages():
    with get_connection() as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                SELECT id, message, created_at
                FROM messages
                ORDER BY id DESC
                LIMIT 20;
                """
            )
            rows = cursor.fetchall()

    return jsonify(
        messages=[
            {
                "id": row["id"],
                "message": row["message"],
                "created_at": row["created_at"].astimezone(timezone.utc).isoformat(),
            }
            for row in rows
        ]
    )


@app.post("/api/v1/messages")
def create_message():
    payload = request.get_json(silent=True) or {}
    message = str(payload.get("message", "")).strip()
    if not message:
        return jsonify(error="message is required"), 400

    with get_connection() as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                INSERT INTO messages (message)
                VALUES (%s)
                RETURNING id, message, created_at;
                """,
                (message[:200],),
            )
            row = cursor.fetchone()

    return (
        jsonify(
            id=row["id"],
            message=row["message"],
            created_at=row["created_at"].astimezone(timezone.utc).isoformat(),
        ),
        201,
    )


wait_for_db()
PY

cat >/etc/systemd/system/nordcloud-api.service <<UNIT
[Unit]
Description=NordCloud Python API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/nordcloud-api
Environment="APP_ENV=${environment}"
Environment="DB_HOST=${db_private_ip}"
Environment="DB_PORT=${db_port}"
Environment="DB_NAME=nordcloud"
Environment="DB_USER=nordcloud_app"
Environment="DB_PASSWORD_B64=${db_app_password_b64}"
ExecStart=/opt/nordcloud-api/venv/bin/gunicorn --bind 0.0.0.0:${app_port} --workers 2 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now nordcloud-api.service
