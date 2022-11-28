# memEx

![old screenshot](https://gitea.bubbletea.dev/shibao/memEx/raw/branch/stable/home.png)

memEx is an easy way to digitize the structured processes of your life.

- Notes: Document notes about individual items or concepts
- Contexts: Provide context around a single topic and hotlink to individual
  concepts in your notes
- Pipelines: Document your processes, attaching contexts to each step.

# Features

- Multi-user: Built with sharing and collaboration in mind
- Privacy: Privacy controls on a per-note, context or pipeline basis
- Convenient: Accessible from any internet-capable device

# Installation

1. Install [Docker Compose](https://docs.docker.com/compose/install/) or alternatively [Docker Desktop](https://docs.docker.com/desktop/) on your machine.
1. Copy the example [docker-compose.yml](https://gitea.bubbletea.dev/shibao/memEx/src/branch/stable/docker-compose.yml). into your local machine where you want.
   Bind mounts are created in the same directory by default.
1. Set the configuration variables in `docker-compose.yml`. You'll need to run
   `docker run -it shibaobun/memex /app/priv/random.sh` to generate a new
   secret key base.
1. Use `docker-compose up` or `docker-compose up -d` to start the container!

The first created user will be created as an admin.

# Configuration

You can use the following environment variables to configure memEx in
[docker-compose.yml](https://gitea.bubbletea.dev/shibao/memEx/src/branch/stable/docker-compose.yml).

- `HOST`: External url to generate links with. Must be set with your hosted
  domain name! I.e. `memex.mywebsite.tld`
- `PORT`: Internal port to bind to. Defaults to `4000`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@memex-db/memex`.
- `ECTO_IPV6`: If set to `true`, Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `docker run -it shibaobun/memex mix phx.gen.secret` and set for server to start.
- `REGISTRATION`: Controls if user sign-up should be invite only or set to
  public. Set to `public` to enable public registration. Defaults to `invite`.
- `LOCALE`: Sets a custom default locale. Defaults to `en_US`.
- `SMTP_HOST`: The url for your SMTP email provider. Must be set
- `SMTP_PORT`: The port for your SMTP relay. Defaults to `587`.
- `SMTP_USERNAME`: The username for your SMTP relay. Must be set!
- `SMTP_PASSWORD`: The password for your SMTP relay. Must be set!
- `SMTP_SSL`: Set to `true` to enable SSL for emails. Defaults to `false`.
- `EMAIL_FROM`: Sets the sender email in sent emails. Defaults to
  `no-reply@HOST` where `HOST` was previously defined.
- `EMAIL_NAME`: Sets the sender name in sent emails. Defaults to "memEx".

---

[![Build
Status](https://drone.bubbletea.dev/api/badges/shibao/memEx/status.svg?ref=refs/heads/dev)](https://drone.bubbletea.dev/shibao/memEx)
[![translation
status](https://weblate.bubbletea.dev/widgets/memEx/-/svg-badge.svg)](https://weblate.bubbletea.dev/engage/memEx/)
