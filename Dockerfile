# -------------------------------------------------
# Builder stage – uses up-to-date Rust
# -------------------------------------------------
FROM rust:1.85 AS builder

WORKDIR /app

# Copy just enough to cache dependencies
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# Optional but strongly recommended: cache dependencies
RUN mkdir -p /app/.cargo && \
    cargo fetch --locked

# Now build the actual binary
RUN cargo build --release --locked

# -------------------------------------------------
# Runtime stage – tiny Debian with audio support
# -------------------------------------------------
FROM debian:bookworm-slim

# Install only the libraries cpal actually needs on Linux
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libasound2 \
        libpulse0 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the builder
COPY --from=builder /app/target/release/audio-visualizer /usr/local/bin/audio-visualizer

# Tell the world we listen on 3000
EXPOSE 3000

# Run it
CMD ["audio-visualizer"]