# ---------- Builder ----------
FROM rust:1.85-slim AS builder

# Install BOTH pkg-config and the ALSA development headers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pkg-config \
        libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Now this will succeed
RUN cargo build --release --locked

# ---------- Runtime ----------
FROM debian:bookworm-slim

# Only runtime libraries needed (no dev headers, no pkg-config)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libasound2 \
        libpulse0 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/audio-visualizer /usr/local/bin/audio-visualizer

EXPOSE 3000
CMD ["audio-visualizer"]