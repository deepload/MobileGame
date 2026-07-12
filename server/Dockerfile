# ---- build stage ----
FROM rust:1-slim AS build
WORKDIR /app

# Cache dependencies: build once with a dummy main, then add real sources.
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs \
    && cargo build --release \
    && rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

# ---- runtime stage ----
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /app/target/release/echo-orbit-server /app/echo-orbit-server

ENV BIND=0.0.0.0:8080
EXPOSE 8080
VOLUME ["/app/data"]

CMD ["/app/echo-orbit-server"]
