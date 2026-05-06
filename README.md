# Easy-openvas

Setup a full OpenVAS service easily on a Debian host with Docker.

## Prerequisites

- A Debian 13 machine.
- A user account with sudo privileges.

## Installation

Copy the OpenVAS installer script to the Debian 13 machine:

```bash
scp Openvas-installer.sh user@debian-server:/tmp/
```

On the Debian 13 machine, make the script executable:

```bash
chmod +x /tmp/Openvas-installer.sh
```

Run the installer with sudo:

```bash
sudo /tmp/Openvas-installer.sh
```

The script installs Docker, downloads the OpenVAS Docker Compose file, starts the containers, and prints the access information at the end.

## Web interface URL

After installation, the OpenVAS web interface is available at:

```text
https://<server-fqdn>
```

If the server FQDN is not available or not resolvable from your browser, use the server IP address instead:

```text
https://<server-ip>
```

The installer configures the OpenVAS web service to listen on all network interfaces. This means the interface can be reached through any IP address assigned to the Debian server, as long as the network and firewall allow access to port `443`.

## Port

No port needs to be added to the URL with the default OpenVAS Docker Compose configuration.

HTTPS uses the standard port `443`, so this is enough:

```text
https://<server-fqdn>
```

Only specify a port if you changed the Docker Compose port mapping manually. In the default OpenVAS Compose file, port `9392` redirects to `443`.

## Network access restriction

By default, this installer makes the OpenVAS web interface reachable from any IP address assigned to the Debian server. Access is not restricted to `127.0.0.1`.

If you want to restrict access, edit `/opt/openvas/compose.yaml` and bind the web ports to a specific address.

To allow access only from the Debian server itself:

```yaml
ports:
  - 127.0.0.1:443:443
  - 127.0.0.1:9392:9392
```

To allow access only through one specific server IP:

```yaml
ports:
  - 192.168.1.42:443:443
  - 192.168.1.42:9392:9392
```

After changing the port binding, recreate the containers:

```bash
sudo docker compose -f /opt/openvas/compose.yaml up -d
```

You can also keep OpenVAS listening on all interfaces and restrict access with a firewall rule, for example with `ufw`:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 443 proto tcp
```

## HTTPS certificate

The default OpenVAS container setup uses a self-signed HTTPS certificate. Browsers will usually display a security warning for this certificate.

For production usage, or to avoid browser warnings, install a TLS certificate issued by a certificate authority trusted by browsers.

## Default credentials

```text
Username: admin
Password: admin
```

Change the default admin password after the first login.

## Mini OpenVAS configuration tutorial

Open the OpenVAS web interface from your browser:

```text
https://<server-fqdn>
```

or:

```text
https://<server-ip>
```

If the browser shows a certificate warning, continue only if you trust the server. This warning is expected with the default self-signed certificate.

Log in with the default credentials:

```text
Username: admin
Password: admin
```

Change the default admin password immediately after the first login.

Before creating a scan, wait until the vulnerability feeds are fully synchronized. The first synchronization can take a long time after the initial installation.

You can check the feed synchronization status in:

```text
Administration > Feed Status
```

If the feeds are not ready yet, the default scan configurations may not be available and task creation can fail.

To scan a host:

1. Go to `Configuration` > `Targets`.
2. Create a new target.
3. Enter a target name.
4. Enter the host IP address or DNS name to scan.
5. Save the target.
6. Go to `Scans` > `Tasks`.
7. Create a new task.
8. Select the target created previously.
9. Start the scan.

Create separate tasks when the scan policy is different, or when you want to organize scans by scope. For example, use different tasks for internal servers, external exposure, workstations, or critical assets.

When the scan is complete, open the task results and review the report. The report lists detected vulnerabilities, severity levels, affected services, and remediation guidance.
