# Dockerized MinIO with NGINX 

This repository provides a Docker setup for running MinIO behind an NGINX reverse proxy with SSL support.

## Prerequisites

- Docker
- Docker Compose
- Optional: SSL certificates for HTTPS configuration (Let's Encrypt)


## Setup

### Clone the repository:
```
git clone https://github.com/TeleDark/MinIO-Cluster.git
cd MinIO-Cluster
```
### Configure the environment variables

Rename the provided `.env.example` file to `.env` and modify the variables as per your setup:
```
mv .env.example .env
```
Edit the `.env` file:

```
MAIL=example@gmail.com
DOMAIN=example.com
NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

MINIO_HTTPS_API=2057
MINIO_HTTP_API=9000

MINIO_ROOT_USER=Username
MINIO_ROOT_PASSWORD=Password
```

### MinIO Cluster Configuration

The `docker-compose` files includes a section that sets up a distributed MinIO cluster consisting of four MinIO instances. MinIO is a high-performance, S3-compatible object storage service. This configuration leverages MinIO's ability to run multiple instances in a cluster for fault tolerance and scalability.

#### Breakdown of the Configuration:

1. **`x-minio-common` Anchor**:
   - This anchor (`&minio-common`) defines a common set of configurations that all four MinIO instances will share. By using an anchor, you avoid duplicating the same settings across multiple services.
   - **Image**: It pulls the MinIO image from `quay.io`.
   - **Command**: The command instructs each MinIO instance to act as a server, distributing storage across the four instances (`minio{1...4}`), with each instance handling two data directories (`data{1...2}`).
   - **Expose**: 
     - Port `9000` is exposed for MinIO API access.
     - Port `9001` is exposed for the MinIO console.
   - **Environment File**: Each instance loads environment variables from the `.env` file, which can include variables like `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` for authentication.
   - **Network**: All MinIO containers are connected to the `backend` network for internal communication.
   - **Healthcheck**: A healthcheck is configured to periodically check the readiness of the MinIO instance by running the `mc ready local` command. If the container does not respond, it retries three times with a 5-second interval and timeout.

2. **MinIO Instances**:
   - Four instances (`minio1`, `minio2`, `minio3`, and `minio4`) are defined, each inheriting the common settings from `x-minio-common` using `<<: *minio-common`.
   - **Container Names & Hostnames**: Each MinIO instance has a unique `container_name` and `hostname` (e.g., `minio1`, `minio2`, etc.).
   - **Volumes**: Each instance is assigned two volumes (e.g., `data1-1`, `data1-2` for `minio1`) that correspond to the directories used for object storage. These volumes provide persistence for the data stored by the MinIO instances.

---

### NGINX Configuration

There are two NGINX configuration files: one for HTTP (`http-nginx.conf.template`) and another for HTTPS (`https-nginx.conf.template`).

**http-nginx.conf.template**:
- Manages upstream servers for MinIO Console and MinIO API.
- Configures client settings, including headers and timeout settings.
- Listens on the defined HTTP ports.

**https-nginx.conf.template**:
- Similar to the HTTP configuration but includes SSL setup.
- Uses Let's Encrypt certificates located in `/letsencrypt/live/${DOMAIN}/`.

---
### Docker Compose Files

- **docker-compose.yaml**: Contains configurations for running MinIO and NGINX with HTTP.
- **docker-compose-https.yaml**: Contains configurations for running MinIO and NGINX with HTTPS.
- **docker-compose-ssl.yaml**: Used to obtain SSL certificates using Certbot.

To obtain SSL certificates, run the following command:

```
docker compose -f docker-compose-ssl.yaml up -d && docker compose -f docker-compose-ssl.yaml down
```

To renew the SSL certificates manually, use:

```
docker compose -f docker-compose-ssl.yaml run --rm certbot renew
```

### Automating SSL Certificate Renewal

If you want to automate the process of renewing your SSL certificates, you can use the following command to schedule a cron job that will run every two months:

```bash
cd MinIO-Cluster && (crontab -l; echo "42 2 1 */2 * bash $(pwd)/certbot/renew.sh >> $(pwd)/nginx/log/ssl-renew.log 2>&1") | sort -u | crontab -
```

This command does the following:

- Adds a cron job that runs at **2:42 AM** on the **1st day of every second month**.
- Executes the script located at `certbot/renew.sh`, which renews your SSL certificates.
- Logs the output and any errors to `$(pwd)/nginx/log/ssl-renew.log`.

By setting this up, your SSL certificates will be automatically renewed and Nginx will be reloaded to apply the new certificates.

--- 


### Access Minio
- **Minio Console http**: http:yourdomain.com
- **Minio Console https**: https:yourdomain.com
- **Minio API http**: `mc alias set myminio_http http://yourdomain:9001 Username Password`
- **Minio API https**: `mc alias set myminio_https https://yourdomain:2057 Username Password`

---

## Running the Setup

1. **For HTTP setup**: Use the following command to start the Docker containers:
```
docker-compose up -d
```

2. **For HTTPS setup**: Run the following command to start the Docker containers:
```
docker-compose -f docker-compose-https.yaml up -d
```
