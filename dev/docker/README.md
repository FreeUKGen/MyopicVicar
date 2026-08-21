# MyopicVicar Local Docker Environment

A quick guide to get [MyopicVicar](https://github.com/FreeUKGen/MyopicVicar) up and running locally.

## Prerequisites

- macOS (tested) or Linux (untested)
- Docker with Docker Compose v2
- A local MyopicVicar fork:
  - Fork [MyopicVicar](https://github.com/FreeUKGen/MyopicVicar)
  - Clone fork locally

This setup is for local development only. Do not add production credentials,
private data, or production configuration to this directory.

## Download Seed Data

Download `seed-data.zip` from the
[MyopicVicar development-data release](https://github.com/sagar-ruby/MyopicVicar-development-data/releases/tag/v1.0.0).

Unzip the archive into `dev/docker` so these directories exist:

```text
dev/docker/seed-data/mongo_import/
dev/docker/seed-data/users/testuser4/
```

The whole `seed-data` directory is ignored by Git but must be present before the
first installation.

## First Install

From the repository root, run:

```bash
# Build and start the app, MariaDB, and MongoDB containers
docker compose -f dev/docker/compose.yaml up -d --build
```

```bash
# Import reference data such as counties, places, churches, and registers
docker compose -f dev/docker/compose.yaml exec -e LOAD_DATA=mongo app mv-setup
```

```bash
# Import sample records and build search indexes and the place cache
docker compose -f dev/docker/compose.yaml exec -e LOAD_DATA=data app mv-setup
```

```bash
# Generate the application's public images, stylesheets, and JavaScript
docker compose -f dev/docker/compose.yaml exec app mv-assets
```

```bash
# Start Rails in the background
docker compose -f dev/docker/compose.yaml exec -d app mv-server
```

The `mongo` step imports reference collections such as counties and places. The
`data` step imports the sample records and builds the search indexes and place
dropdown cache. Run them in that order on a fresh database; the data step can
take several minutes.

## Services

Check the containers with:

```bash
docker compose -f dev/docker/compose.yaml ps
```

| Service | Host address |
|---------|--------------|
| Rails | <http://127.0.0.1:3001> |
| MariaDB 10.3 | `127.0.0.1:3307` |
| MongoDB 4.4 | `127.0.0.1:27018` |

Database and gem data are stored in named Docker volumes and survive a normal
container restart.

## First Manual Test

Open <http://localhost:3001> then use the search to confirm that this search returns Mary Fowler's burial at Acle on 7 August 1805:

```text
Surname: Fowler
Forename(s): Mary
First year: 1805
Last year: 1805
Record Type: Burial
County: Norfolk
Place: Acle
```

## Daily Use

Start the containers and Rails:

```bash
docker compose -f dev/docker/compose.yaml up -d
docker compose -f dev/docker/compose.yaml exec -d app mv-server
```

Stop the containers:

```bash
docker compose -f dev/docker/compose.yaml down
```

## Useful Commands

```bash
# Follow Rails logs
docker compose -f dev/docker/compose.yaml logs -f app

# Open a Rails console
docker compose -f dev/docker/compose.yaml exec app mv-console

# Run RSpec
docker compose -f dev/docker/compose.yaml exec app mv-rspec

# Open a shell in the app container
docker compose -f dev/docker/compose.yaml exec app bash
```

## Troubleshooting

### Missing places or search results

Both seed commands must finish successfully. The place dropdown uses a cache
built by `LOAD_DATA=data`; importing only the Mongo reference collections is not
enough.

### Missing images, styling, or JavaScript

Regenerate the public assets:

```bash
docker compose -f dev/docker/compose.yaml exec app mv-assets
```

### Rails reports an existing server

Run `mv-server` again. It removes a stale `tmp/pids/server.pid` when no matching
server process is running.
