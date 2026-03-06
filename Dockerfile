ARG RUST_VERSION=1.94
ARG APP_NAME=Reveaal

FROM docker.io/library/rust:${RUST_VERSION}-alpine AS build
ARG APP_NAME

WORKDIR /app

RUN apk add --no-cache clang lld musl-dev git protoc protobuf-dev

ENV PROTOC=/usr/bin/protoc
ENV PROTOC_INCLUDE=/usr/include

RUN --mount=type=bind,source=src,target=src \
    --mount=type=bind,source=Ecdar-ProtoBuf,target=Ecdar-ProtoBuf \
    --mount=type=bind,source=benches,target=benches \
    --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=cache,target=/app/target \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --locked --release --bin "${APP_NAME}" && \
    cp "./target/release/${APP_NAME}" /bin/server

FROM docker.io/library/alpine:3.18 AS final

ARG UID=10001
RUN adduser -D -H -u "${UID}" appuser

COPY --from=build /bin/server /bin/server

ENV ADDRESS=0.0.0.0
ENV PORT=8000

USER appuser

EXPOSE 8000

ENTRYPOINT ["/bin/sh", "-c", "exec /bin/server serve \"${ADDRESS}:${PORT}\""]