#!/bin/bash
set -euxo pipefail

# Tier presentation : vrai serveur web Nginx.
# Il sert une page statique et proxifie les appels /api vers le tier application prive.
dnf install -y nginx

cat >/usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NordCloud</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; background: #f6f8fb; color: #172033; }
    main { max-width: 820px; margin: auto; background: white; padding: 2rem; border: 1px solid #d9e1ec; }
    code, pre { background: #eef2f7; padding: .2rem .35rem; }
    button { padding: .6rem .9rem; border: 1px solid #172033; background: #172033; color: white; cursor: pointer; }
    input { padding: .6rem; min-width: 280px; }
    li { margin: .4rem 0; }
  </style>
</head>
<body>
  <main>
    <h1>NordCloud - Tier presentation</h1>
    <p>Frontend servi par Nginx. Les appels <code>/api</code> sont transmis au tier application prive.</p>

    <section>
      <h2>Etat API</h2>
      <pre id="health">Chargement...</pre>
    </section>

    <section>
      <h2>Messages PostgreSQL</h2>
      <form id="message-form">
        <input id="message-input" name="message" placeholder="Nouveau message" maxlength="200">
        <button type="submit">Ajouter</button>
      </form>
      <ul id="messages"></ul>
    </section>
  </main>

  <script>
    async function refreshHealth() {
      const response = await fetch("/health");
      document.querySelector("#health").textContent = JSON.stringify(await response.json(), null, 2);
    }

    async function refreshMessages() {
      const response = await fetch("/api/v1/messages");
      const payload = await response.json();
      const list = document.querySelector("#messages");
      list.innerHTML = "";
      payload.messages.forEach((item) => {
        const li = document.createElement("li");
        li.textContent = item.id + " - " + item.message + " (" + item.created_at + ")";
        list.appendChild(li);
      });
    }

    document.querySelector("#message-form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const input = document.querySelector("#message-input");
      const message = input.value.trim();
      if (!message) return;
      await fetch("/api/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message })
      });
      input.value = "";
      await refreshMessages();
      await refreshHealth();
    });

    refreshHealth().catch((error) => {
      document.querySelector("#health").textContent = error.message;
    });
    refreshMessages().catch(console.error);
  </script>
</body>
</html>
HTML

cat >/etc/nginx/conf.d/nordcloud.conf <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /health {
        proxy_pass http://${app_private_ip}:${app_port}/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://${app_private_ip}:${app_port}/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX

rm -f /etc/nginx/conf.d/default.conf
nginx -t
systemctl enable --now nginx
