FROM ubuntu:24.04 AS build

RUN apt-get update && apt-get install -y curl ca-certificates build-essential git && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
ENV PATH="/root/.moon/bin:${PATH}"

WORKDIR /app
COPY . .
RUN moon update && moon build --target native --release

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/_build/native/release/build/cmd/main/main.exe /usr/local/bin/codeiq

EXPOSE 8787
VOLUME ["/data/cache"]

ENV COGNA_CACHE_STORE_DIR=/data/cache

ENTRYPOINT ["/usr/local/bin/codeiq", "serve", "--port", "8787"]
