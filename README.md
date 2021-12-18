# Traefik with docker quick start

This is a simple repository that allows to system-wide install `traefik` in a
container using `docker-compose`.

## Installation

1. Clone this repository somewhere on your machine, i.e. home directory:

```bash
git clone https://github.com/lexuzieel/traefik-quick-start.git traefik
```

2. Go to the newly created directory:

```bash
cd traefik
```

3. Bring up traefik instance:

```bash
docker-compose up -d
```

This will create `traefik` docker-compose project with a single container
`traefik_reverse-proxy_1` that listens on ports 80, 443 and 8080 (dashboard) on
`localhost`.

## Usage

### Stand-alone container

After bringing up an instance of `traefik`, it will 
[automatically watch](https://doc.traefik.io/traefik/getting-started/concepts/#auto-service-discovery) 
for new containers on your system. In order to tell `traefik` to create a 
route to your container, simply
[annotate it](https://doc.traefik.io/traefik/providers/docker):

```bash
docker run --rm \
-l 'traefik.enable=true' \
-l 'traefik.http.routers.nginx-example.rule=Host("nginx.example.localhost")' \
-l 'traefik.http.routers.nginx-example.entrypoints=web' \
-l 'traefik.http.services.nginx-example.loadbalancer.server.port=80' \
-l 'traefik.docker.network=traefik_overlay' \
--network traefik_overlay \
nginx
```

> Pay close attention to the `--network` parameter. In order for the Traefik to
> "see" this container they have to be connected to the same network, since
> originally containers reside in different networks and cannot access each
> other.

Now you can access your container at `nginx.example.localhost`:

<p style="text-align: center">
    <img src="docs/nginx-example.png">
</p>

### Docker-Compose service

Besides single containers you can also annotate `docker-compose` services and
since they are regular containers they will also be picked up by Traefik.

Given a `docker-compose.yml` file that descibes two services, a front-end and
a back-end:

```yaml
version: '3'

services:
  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      - REDIS_HOSTS=local:redis:6379
    # This service is exposed by Traefik, so no need to expose the ports
    # ports:
    #   - "8081:8081"
    networks:
      - traefik
      # docker-compose project network
      # (to allow the backend to connect to redis)
      - default 
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.redis-commander.loadbalancer.server.port=8081"
      - "traefik.http.routers.redis-commander.rule=Host(`redis-commander.localhost`)"
      - "traefik.http.routers.redis-commander.entrypoints=web"
      - "traefik.docker.network=traefik_overlay"
  redis:
    image: redis

networks:
  traefik:
    name: traefik_overlay
```

You can specify a reference to the `traefik_overlay` network in the list of
docker-compose project networks:

```yml
networks:
  traefik:
    name: traefik_overlay
```

Then, in the service that you want to expose, add this network:

```yml
services:
  my-service:
    ...
    networks:
      - traefik
      - default # <-- Add default network if you want to connect 
                # to other services inside the docker-compose project
```

Bring up this docker-compose project:

```bash
docker-compose --project-name example --file docker-compose.example.yml up -d
```

Now you can access your service at `redis-commander.localhost`:

<p style="text-align: center">
    <img src="docs/redis-commander.png">
</p>


## Configuration

This project has a sample `traefik.yml` configuration file that you can change
freely. In contrast to the official sample file, it has
`providers.docker.exposedByDefault` set to `false` by default.
Consult [configuration introduction](https://doc.traefik.io/traefik/getting-started/configuration-overview/)
page of Traefik documentation for more details.
