FROM elixir:1.15.4-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git python3

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY lib lib
COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix do phx.digest, gettext.extract

# compile and build release
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:latest AS app

RUN apk upgrade --no-cache && \
    apk add --no-cache bash openssl libssl1.1 libcrypto1.1 libgcc libstdc++ ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/memex ./
COPY --from=build --chown=nobody:nobody /app/priv /app/priv
RUN chmod +x /app/priv/random.sh

ENV HOME=/app

CMD ["bin/memex", "start"]
