#!/bin/bash

# Run the docker-compose command to renew SSL certificates
docker compose -f docker-compose-ssl.yaml run --rm certbot renew

#Reload Nginx after certificate renewal
docker compose -f docker-compose-https.yaml exec nginx nginx -s reload