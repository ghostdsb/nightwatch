FROM hexpm/elixir:1.12.2-erlang-24.0.5-alpine-3.14.0 as build

# install build dependencies
RUN apk add --no-cache build-base npm git py-pip


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


COPY priv priv

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists

# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:3.14.0 AS app

RUN apk add --no-cache openssl ncurses-libs libgcc libstdc++

WORKDIR /app

RUN chown root:root /app

USER root:root

COPY --from=build --chown=root:root /app/_build/prod/rel/nightwatch ./
COPY entrypoint.sh .

ENV HOME=/app

# # Run the Phoenix app
CMD ["sh", "./entrypoint.sh"]