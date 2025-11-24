# Use the latest stable Rust (or at least 1.81+)
FROM rust:1.85 AS builder   # or rust:latest

WORKDIR /app
COPY . .

# Optional: cache dependencies better
RUN cargo fetch

# Build the release binary
RUN cargo build --release --locked

# Runtime stage - slim Debian with audio libraries
FROM debian:bookworm-slim

# Install required audio libraries (ALSA + PulseAudio client libs)
RUN apt-get update && apt-get install -y \
    libasound2 \
    libpulse0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary
COPY --from=builder /app/target/release/audio-visualizer /usr/local/bin/audio-visualizer

# Expose port
EXPOSE 3000

# Run
CMD ["audio-visualizer"]