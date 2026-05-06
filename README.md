# Easy-openvas

Setup a full OpenVAS service easily on a Debian host with Docker.

## Installation

Run the installer as root:

```bash
sudo ./Openvas-installer.sh
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

## Port

No port needs to be added to the URL with the default OpenVAS Docker Compose configuration.

HTTPS uses the standard port `443`, so this is enough:

```text
https://<server-fqdn>
```

Only specify a port if you changed the Docker Compose port mapping manually. In the default OpenVAS Compose file, port `9392` redirects to `443`.

## HTTPS certificate

The default OpenVAS container setup uses a self-signed HTTPS certificate. Browsers will usually display a security warning for this certificate.

For production usage, or to avoid browser warnings, install a TLS certificate issued by a certificate authority trusted by browsers.

## Default credentials

```text
Username: admin
Password: admin
```

Change the default admin password after the first login.
