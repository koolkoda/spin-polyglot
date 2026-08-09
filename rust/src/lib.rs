use spin_sdk::http::{IntoResponse, Request, Response};
use spin_sdk::http_service;

/// HTTP handler for the Rust component.
#[http_service]
async fn handle_rust(req: Request) -> anyhow::Result<impl IntoResponse> {
    let path = req
        .headers()
        .get("spin-path-info")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("/");

    let body = serde_json::json!({
        "component": "rust",
        "message": "Hello from Spin",
        "path": path,
    });

    Ok(Response::builder()
        .status(200)
        .header("content-type", "application/json")
        .body(body.to_string()))
}
