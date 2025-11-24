# Use Rust slim image (already has pkg-config + build tools)
FROM rust:1.85-slim AS builder

# Install only the missing dev package
RUN apt-get update && \
    apt-get install -y --no-install-recommends libasound2-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cargo build --release --locked

# Runtime (tiny)
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libasound2 libpulse0 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/audio-visualizer /usr/local/bin/
EXPOSE 3000
CMD ["audio-visualizer"]