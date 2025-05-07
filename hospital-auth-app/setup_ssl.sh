## Copyright (c) HashiCorp, Inc.
## SPDX-License-Identifier: MPL-2.0
#!/bin/bash

# Variables
DOMAIN="karrio.ianthony.com"
WEBROOT="/var/www/certbot"

# Step 1: Install NGINX and Certbot
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Step 2: Setup webroot for Certbot challenge
sudo mkdir -p $WEBROOT
sudo chown -R www-data:www-data $WEBROOT

# Step 3: Create temporary NGINX config to allow HTTP challenge
cat <<EOF | sudo tee /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        return 404;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Step 4: Run Certbot with webroot plugin
sudo certbot certonly --webroot -w $WEBROOT -d $DOMAIN

# Step 5: Replace NGINX config with SSL version
cat <<EOF | sudo tee /etc/nginx/sites-available/$DOMAIN
server {
    listen 80;
    server_name $DOMAIN;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Step 6: Reload NGINX with HTTPS config
sudo nginx -t && sudo systemctl reload nginx

# Done
echo "✅ SSL setup complete for https://$DOMAIN"
