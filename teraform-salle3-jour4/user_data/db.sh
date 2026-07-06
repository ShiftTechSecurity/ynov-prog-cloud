#!/bin/bash
set -euxo pipefail

# Tier donnees : PostgreSQL ecoute uniquement dans le subnet prive.
# L'acces applicatif est limite a l'IP privee stable du tier app.
dnf install -y postgresql15 postgresql15-server xfsprogs

DB_APP_PASSWORD="$(printf '%s' '${db_app_password_b64}' | base64 -d)"

DATA_DEVICE=""
for _ in $(seq 1 60); do
  for candidate in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
    if [ -b "$candidate" ]; then
      DATA_DEVICE="$candidate"
      break
    fi
  done

  if [ -n "$DATA_DEVICE" ]; then
    break
  fi

  sleep 5
done

if [ -n "$DATA_DEVICE" ]; then
  if ! blkid "$DATA_DEVICE"; then
    mkfs.xfs -f "$DATA_DEVICE"
  fi

  mkdir -p /var/lib/pgsql
  DEVICE_UUID="$(blkid -s UUID -o value "$DATA_DEVICE")"

  if ! grep -q "$DEVICE_UUID" /etc/fstab; then
    echo "UUID=$DEVICE_UUID /var/lib/pgsql xfs defaults,nofail 0 2" >>/etc/fstab
  fi

  mount /var/lib/pgsql || mount "$DATA_DEVICE" /var/lib/pgsql
fi

chown -R postgres:postgres /var/lib/pgsql
chmod 700 /var/lib/pgsql

postgresql-setup --initdb

cat >>/var/lib/pgsql/data/postgresql.conf <<CONF
listen_addresses = '*'
port = ${db_port}
password_encryption = 'scram-sha-256'
CONF

cat >>/var/lib/pgsql/data/pg_hba.conf <<HBA
host    nordcloud    nordcloud_app    ${app_private_ip}/32    scram-sha-256
HBA

systemctl enable --now postgresql

sudo -u postgres psql -v app_password="$DB_APP_PASSWORD" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nordcloud_app') THEN
    CREATE ROLE nordcloud_app LOGIN;
  END IF;
END
$$;

ALTER ROLE nordcloud_app WITH LOGIN PASSWORD :'app_password';

SELECT 'CREATE DATABASE nordcloud OWNER nordcloud_app'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nordcloud')\gexec
SQL

sudo -u postgres psql -d nordcloud <<'SQL'
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE messages OWNER TO nordcloud_app;
GRANT CONNECT ON DATABASE nordcloud TO nordcloud_app;
GRANT USAGE, CREATE ON SCHEMA public TO nordcloud_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO nordcloud_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO nordcloud_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO nordcloud_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO nordcloud_app;

INSERT INTO messages (message)
SELECT 'NordCloud PostgreSQL backend ready'
WHERE NOT EXISTS (SELECT 1 FROM messages);
SQL
