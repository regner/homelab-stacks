# homelab-stacks

This is a repo of Docker Swarm stacks for my home lab. The stacks are created
first and foremost with home lab use in mind. So things like Grafana configs are
done by hand in the GUI rather than some complicated git-ops style deployment.
Yes it is less reproducable if I lose all my data and have to recreate from
scratch. But this is a home lab, not production. Simple and easy is what I want.

Since all application data is stored on the NAS it should be a simple act of
reinstalling the OS, running init script, and joining swarm cluster if needed.

## Security Note

Several applications are exposed without username/password or with simple
passwords. Again this is home use and those are exposed just within my home
network. VLANS and firewalls mean only I should have access and if someone is
in my network I am fucked anyways. Again this is not production.

## Expoected Plugins

```bash
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

```bash
vim /etc/docker/daemon.json
```

```json
{
    "debug" : false,
    "log-driver": "loki",
    "log-opts": {
        "loki-url": "http://<ip of manager node>:8000/api/prom/push",
        "loki-batch-size": "400"
    }
}
```

## Expected Secrets


grafana_admin_password
```text
something secure
```

## Random Notes

* Be sure to create the data directories first when adding a new application that needs
a volume mount.
* If the container allows defining a UID and GID set them to 1000 and chown the directories
to dockerdata.
* There is only 1 manager node (see home lab, not production) and public ports
get forwarded to it.
* In general anything that requires a direct port being forwarded to it is pinned to
the manager node. Traefik and the UniFi controller for example.
* The expectation is that all nodes have the app_data and video NFS shares mounted. Each
application then gets a dedicated folder in app_data and as many sub folders as required
for different mounts.
* Traefik exposes 3 ports. 80 and 443 should be exposed to the public, 8000 is not exposed
and used to expose internal only services. Might consider moving these to 443 only and adding
authentication. Why risk though?
* *.${DNS_EXTERNAL} is pointed to public IP
* *.${DNS_internal} is pointed to manager IP
* The Transmission config has a whitelist, if DNS for Transmission changes that needs an update

## Prometheus Notes

### Pre Deploy

```bash
mkdir -p /data/app_data/prometheus/config
mkdir -p /data/app_data/prometheus/data
mkdir -p /data/app_data/grafana/config
mkdir -p /data/app_data/grafana/data
mkdir -p /data/app_data/alertmanager/config

# Copy the folowing files to specific locations:
# prometheus/alerts.yaml       -> /data/app_data/prometheus/config
# prometheus/prometheus.yaml   -> /data/app_data/prometheus/config
# prometheus/alertmanager.yaml -> /data/app_data/alertmanager/config
```

### Post Deploy

* Log into Grafana
* Add a Prometheus data source
* Set URL to `http://prometheus:9090`
* Save and test
* Go find some dashboards to use

## UniFi Controller Notes

### Ports

#### Exposed

These are the ports to expose on the host of the UniFi Controller:

* UDP 3478: For STUN.
* TCP 8080: For device and controller communication.
* TCP 8443: For controller GUI/API as seen in a web browser
* TCP 8880: For HTTP portal redirection.
* TCP 8843: For HTTPS portal redirection.

##### Port 3478

Traefik doesn't support proxying UDP packets, so exposing this on the host and publicly. Everyone
seems to say that is safe to do.

##### Port 8080

This port is used for devices to communicate with the Controller. While communication isn't done
over a secure socket the payloads do appear to be encrypted. So it is safe, and required for other
sites, to expose this port publicly.

##### Port 8443

The UniFi Controller appears to inspect the referer header and requires the protocol to be HTTPS. Since
I am using httpChallenge for Traefik I need to be able to first configure the USG and forward ports
before a Lets Encrypt cert can be provided. Due to that, and simply as a fall back, exposing 8443
seems like a grand idea. This will NOT be exposed to the internet.

##### Port 8880 and 8843

I am hoping I can get around exposing these on the host and instead expose via Traefik. More testing is
required before I have an answer.

#### Not Exposed

* TCP 6789: For UniFi mobile speed test, I don't need or care about it.
* TCP 27117: For MongoDB and that is run in the same container so no need to expose.
* UDP 10001: My controller runs in a different subnet anyways so no point exposing. Do NOT
expose this to the internet. See [here](https://www.zdnet.com/article/over-485000-ubiquiti-devices-vulnerable-to-new-attack/).
* UDP 5656-5699: Ports used by AP-EDU broadcasting and I don't have any.
* UDP 1900: For "Make controller discoverable on L2 network" in controller settings. Don't care.
