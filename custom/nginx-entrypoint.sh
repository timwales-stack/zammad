#!/bin/bash
# Black Raven Service Desk — Nginx Entrypoint Wrapper
# Runs the normal Zammad entrypoint, then patches the nginx config
# to inject custom CSS via sub_filter before nginx starts.

# Run the original entrypoint in background to let it generate the config
/opt/zammad/bin/docker-entrypoint zammad-nginx &
PID=$!

# Wait for the nginx config to be generated
while [ ! -f /etc/nginx/sites-enabled/default ] || ! grep -q "upstream" /etc/nginx/sites-enabled/default 2>/dev/null; do
  sleep 1
done

# Wait a moment for the file to be fully written
sleep 2

# Inject sub_filter into the location / block for CSS injection
if ! grep -q "sub_filter" /etc/nginx/sites-enabled/default; then
  sed -i '/location \/ {/,/}/ {
    /gzip_proxied any;/a\
\
    # Black Raven CSS injection\
    sub_filter "</head>" "<link rel=\\"stylesheet\\" href=\\"/assets/blackraven-theme.css\\" />\\n</head>";\
    sub_filter_once on;\
    sub_filter_types text/html;\
    proxy_set_header Accept-Encoding "";
  }' /etc/nginx/sites-enabled/default

  # Reload nginx to pick up changes
  nginx -s reload 2>/dev/null || true
fi

# Wait for the original process
wait $PID
