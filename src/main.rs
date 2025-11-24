use axum::{
    extract::{State, WebSocketUpgrade},
    response::Html,
    routing::get,
    Router,
};
use axum::extract::ws::{Message, WebSocket};
use futures_util::{SinkExt, StreamExt};
use serde::Serialize;
use std::net::SocketAddr;
use tokio::sync::broadcast;
use tower_http::services::ServeDir;

mod audio;
use audio::start_audio_stream;

#[derive(Serialize)]
struct SpectrumData {
    bins: Vec<f32>,
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(tx): State<broadcast::Sender<Vec<f32>>>,
) -> axum::response::Response {
    ws.on_upgrade(move |socket| handle_socket(socket, tx))
}

async fn handle_socket(socket: WebSocket, tx: broadcast::Sender<Vec<f32>>) {
    let mut rx = tx.subscribe();
    let (mut sender, mut _receiver) = socket.split();

    while let Ok(bins) = rx.recv().await {
        let data = SpectrumData { bins };
        if let Ok(json) = serde_json::to_string(&data) {
            let _ = sender.send(Message::Text(json)).await;
        }
    }
}

async fn index() -> Html<String> {
    Html(
        std::fs::read_to_string("static/index.html")
            .unwrap_or_else(|_| "<h1>index.html not found</h1>".into()),
    )
}

#[tokio::main]
async fn main() {
    // Create a subscriber that formats output and prints it
    tracing_subscriber::fmt::init();

    let (tx, _rx) = broadcast::channel(100);
    let _stream = start_audio_stream(tx.clone());

    let app = Router::new()
        .route("/", get(index))
        .route("/ws", get(ws_handler))
        .with_state(tx)
        .nest_service("/static", ServeDir::new("static"));

    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    tracing::info!("Visualizer: http://localhost:3000");

    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}