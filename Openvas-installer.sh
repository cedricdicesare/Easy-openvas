#!/bin/bash

set -e

echo "=================================================="
echo " OpenVAS Docker installation script"
echo "=================================================="
echo ""

if [ "$EUID" -ne 0 ]; then
  echo "Error: this script must be run as root."
  echo "Example: sudo ./install-openvas.sh"
  exit 1
fi

echo "[1/9] Detecting server FQDN and IP address..."

SERVER_FQDN="$(hostname -f 2>/dev/null || hostname)"
SERVER_IP="$(hostname -I | awk '{print $1}')"

if [ -z "$SERVER_FQDN" ]; then
  SERVER_FQDN="$SERVER_IP"
fi

echo "Detected FQDN: $SERVER_FQDN"
echo "Detected IP:   $SERVER_IP"
echo ""

echo "[2/9] Updating package list and installing prerequisites..."

apt update
apt install -y ca-certificates curl gnupg

echo "Prerequisites installed."
echo ""

echo "[3/9] Removing conflicting Docker packages if present..."

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  apt remove -y "$pkg" || true
done

echo "Conflicting packages removed or not present."
echo ""

echo "[4/9] Installing Docker repository key..."

install -m 0755 -d /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg

curl -fsSL https://download.docker.com/linux/debian/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo "Docker key installed."
echo ""

echo "[5/9] Adding Docker APT repository..."

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update

echo "Docker repository added."
echo ""

echo "[6/9] Installing Docker Engine and Docker Compose plugin..."

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

echo "Docker installed and started."
echo ""

docker --version
docker compose version
echo ""

echo "[7/9] Preparing OpenVAS installation directory..."

OPENVAS_DIR="/opt/openvas"
COMPOSE_FILE="$OPENVAS_DIR/compose.yaml"

mkdir -p "$OPENVAS_DIR"
cd "$OPENVAS_DIR"

echo "OpenVAS directory: $OPENVAS_DIR"
echo ""

echo "[8/9] Downloading OpenVAS Docker Compose file..."

curl -f -L https://greenbone.github.io/docs/latest/_static/compose.yaml -o "$COMPOSE_FILE"

echo "Compose file downloaded:"
echo "$COMPOSE_FILE"
echo ""

echo "[9/9] Starting OpenVAS containers..."

docker compose -f "$COMPOSE_FILE" pull

echo ""
echo "Starting containers. Some data containers may take several minutes to become healthy..."
docker compose -f "$COMPOSE_FILE" up -d || true

echo ""
echo "Waiting for scap-data container to become healthy..."

SCAP_CONTAINER="$(docker compose -f "$COMPOSE_FILE" ps -q scap-data || true)"

if [ -z "$SCAP_CONTAINER" ]; then
  echo "Error: scap-data container was not found."
  echo "Showing current container status:"
  docker compose -f "$COMPOSE_FILE" ps
  exit 1
fi

MAX_ATTEMPTS=60
SLEEP_SECONDS=15
ATTEMPT=1

while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
  HEALTH_STATUS="$(docker inspect --format='{{.State.Health.Status}}' "$SCAP_CONTAINER" 2>/dev/null || echo "unknown")"

  echo "scap-data health status: $HEALTH_STATUS - attempt $ATTEMPT/$MAX_ATTEMPTS"

  if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo "scap-data is healthy."
    break
  fi

  if [ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]; then
    echo ""
    echo "Error: scap-data did not become healthy in time."
    echo ""
    echo "Last logs from scap-data:"
    docker compose -f "$COMPOSE_FILE" logs --tail=100 scap-data
    echo ""
    echo "Current container status:"
    docker compose -f "$COMPOSE_FILE" ps
    exit 1
  fi

  sleep "$SLEEP_SECONDS"
  ATTEMPT=$((ATTEMPT + 1))
done

echo ""
echo "Starting remaining OpenVAS services..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "Current container status:"
docker compose -f "$COMPOSE_FILE" ps
echo ""

echo "=================================================="
echo " Installation completed"
echo "=================================================="
echo ""
echo "OpenVAS web interface should be available at:"
echo ""
echo "  https://$SERVER_FQDN"
echo ""
echo "Port information:"
echo "  HTTPS uses the standard port 443, so no port needs to be added"
echo "  to the URL unless you changed the Docker Compose port mapping."
echo "  In the default OpenVAS Compose file, port 9392 redirects to 443."
echo ""

if [ -n "$SERVER_IP" ] && [ "$SERVER_IP" != "$SERVER_FQDN" ]; then
  echo "Alternative URL using the server IP:"
  echo ""
  echo "  https://$SERVER_IP"
  echo ""
fi

echo "Default credentials:"
echo ""
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Important:"
echo "  Change the default admin password after the first login."
echo ""
echo "Certificate warning:"
echo "  If your browser displays a certificate warning, this is expected"
echo "  when OpenVAS uses its default self-signed HTTPS certificate."
echo "  For a warning-free browser experience, install a TLS certificate"
echo "  issued by a certificate authority trusted by browsers."
echo ""
echo "Useful commands:"
echo ""
echo "  Check containers:"
echo "    docker compose -f $COMPOSE_FILE ps"
echo ""
echo "  Follow logs:"
echo "    docker compose -f $COMPOSE_FILE logs -f"
echo ""
echo "  Check scap-data logs:"
echo "    docker compose -f $COMPOSE_FILE logs --tail=100 scap-data"
echo ""
echo "  Restart OpenVAS:"
echo "    docker compose -f $COMPOSE_FILE up -d"
echo ""
echo "  Stop OpenVAS:"
echo "    docker compose -f $COMPOSE_FILE down"
echo ""
