FROM rust:1.75-slim AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libasound2 libpulse0  # For audio deps
COPY --from=builder /app/target/release/audio-visualizer /usr/local/bin/
CMD ["/usr/local/bin/audio-visualizer"]