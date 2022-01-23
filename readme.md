# Lokal

Lokal is a local business aggregation site helping you to shop locally by
providing a one-stop-shop for your local community. Set your profile and start
shopping today!

# Features

- User Registration/Sign in via `phx_gen_auth`
- `Dockerfile` and example `docker-compose.yml`
- Automatic migrations in `MIX_ENV=prod` or Docker image
- JS linting with [standard.js](https://standardjs.com), HEEx linting with
  [heex_formatter](https://github.com/feliperenan/heex_formatter)

# Installation

1. Clone the repo
2. Run `mix setup`
3. Run `mix phx.server` to start the development server

# Configuration

For development, I recommend setting environment variables with
[direnv](https://direnv.net).

## `MIX_ENV=dev`

In `dev` mode, Lokal will listen for these environment variables on compile.

- `HOST`: External url to generate links with. Set these especially if you're
  behind a reverse proxy. Defaults to `localhost`.
- `PORT`: External port for urls. Defaults to `443`.
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@localhost/lokal_dev`.

## `MIX_ENV=prod`

In `prod` mode (or in the Docker container), Lokal will listen for these environment variables at runtime.

- `HOST`: External url to generate links with. Set these especially if you're
  behind a reverse proxy. Defaults to `localhost`.
- `PORT`: Internal port to bind to. Defaults to `4000` and attempts to bind to
  `0.0.0.0`. Must be reverse proxied!
- `DATABASE_URL`: Controls the database url to connect to. Defaults to
  `ecto://postgres:postgres@lokal-db/lokal`.
- `ECTO_IPV6`: Controls if Ecto should use ipv6 to connect to PostgreSQL.
  Defaults to `false`.
- `POOL_SIZE`: Controls the pool size to use with PostgreSQL. Defaults to `10`.
- `SECRET_KEY_BASE`: Secret key base used to sign cookies. Must be generated
  with `mix phx.gen.secret` and set for server to start.

