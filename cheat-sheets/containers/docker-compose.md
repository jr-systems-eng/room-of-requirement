# Docker and Docker Compose

Quick-reference for container inspection, Compose operations, logs, storage, networking, and GPU checks.

## Docker basics

```bash
docker version
docker info
docker ps
docker ps -a
docker images
docker stats
docker system df
```

## Inspect a container

```bash
docker inspect CONTAINER
docker top CONTAINER
docker port CONTAINER
docker logs CONTAINER
docker logs -f CONTAINER
docker logs --tail 100 CONTAINER
```

## Shell into a container

```bash
docker exec -it CONTAINER bash
docker exec -it CONTAINER sh
```

Run one command:

```bash
docker exec CONTAINER COMMAND
```

## Lifecycle

```bash
docker start CONTAINER
docker stop CONTAINER
docker restart CONTAINER
docker rm CONTAINER
docker rm -f CONTAINER
```

## Run containers

```bash
docker run --rm IMAGE COMMAND
docker run -it --rm IMAGE bash
docker run -d --name NAME -p 8080:80 IMAGE
```

## Volumes and mounts

```bash
docker volume ls
docker volume inspect VOLUME
docker inspect CONTAINER --format '{{json .Mounts}}'
```

Bind mount example:

```bash
docker run --rm -v /host/path:/container/path IMAGE
```

## Networks

```bash
docker network ls
docker network inspect NETWORK
docker inspect CONTAINER --format '{{json .NetworkSettings.Networks}}'
```

## Compose basics

```bash
docker compose version
docker compose config
docker compose ps
docker compose up -d
docker compose down
docker compose restart
docker compose pull
docker compose logs
docker compose logs -f
docker compose logs --tail 100 SERVICE
```

Specific file:

```bash
docker compose -f /path/compose.yaml ps
docker compose -f /path/compose.yaml up -d
```

Specific service:

```bash
docker compose up -d SERVICE
docker compose restart SERVICE
docker compose logs -f SERVICE
```

## Recreate after config/image change

```bash
docker compose pull
docker compose up -d
```

Force recreation:

```bash
docker compose up -d --force-recreate SERVICE
```

## Validate Compose YAML

```bash
docker compose config
```

This expands variables and catches many syntax/configuration errors before deployment.

## Health checks

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker inspect CONTAINER --format '{{json .State.Health}}'
```

## GPU / NVIDIA

Host:

```bash
nvidia-smi
```

Container runtime test:

```bash
docker run --rm --gpus all nvidia/cuda:TAG nvidia-smi
```

Container GPU visibility:

```bash
docker exec CONTAINER nvidia-smi
```

## Cleanup

```bash
docker container prune
docker image prune
docker volume prune
docker network prune
docker system prune
```

Do **not** casually run:

```bash
docker system prune -a --volumes
```

It can remove unused images and volumes containing data.

## Fast container troubleshooting

```text
1. docker compose ps / docker ps -a
2. docker logs --tail 100 CONTAINER
3. docker inspect CONTAINER
4. docker exec ... check process/config/files
5. ss/curl from host for published port
6. inspect mounts and networks
7. docker compose config
8. recreate only after identifying likely config/image issue
```
