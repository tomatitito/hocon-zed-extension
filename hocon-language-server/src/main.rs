use std::sync::Arc;

use serde_json::Value;
use tower_lsp::jsonrpc::{Error, Result};
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer, LspService, Server};

/// The main HOCON language server implementation
struct HoconLanguageServer {
    client: Client,
}

#[tower_lsp::async_trait]
impl LanguageServer for HoconLanguageServer {
    async fn initialize(&self, params: InitializeParams) -> Result<InitializeResult> {
        // Log the initialization request
        log::info!("Initializing HOCON language server...");
        log::info!("Client capabilities: {:#?}", params.capabilities);

        // Print a nice greeting message to demonstrate client communication
        if let Some(client_info) = params.client_info {
            self.client
                .log_message(
                    MessageType::INFO,
                    format!("Hello {} {}!", client_info.name, client_info.version.unwrap_or_default()),
                )
                .await;
        }

        // Define the server capabilities
        // For now we're only implementing the minimum needed
        let capabilities = ServerCapabilities {
            // We're just returning minimal capabilities for now
            text_document_sync: Some(TextDocumentSyncCapability::Kind(
                TextDocumentSyncKind::INCREMENTAL,
            )),
            // Add more capabilities as your language server grows
            ..ServerCapabilities::default()
        };

        // Return the server capabilities and some basic info
        Ok(InitializeResult {
            capabilities,
            server_info: Some(ServerInfo {
                name: "HOCON Language Server".to_string(),
                version: Some("0.1.0".to_string()),
            }),
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, "HOCON language server initialized!")
            .await;

        log::info!("Language server initialized");
    }

    async fn shutdown(&self) -> Result<()> {
        log::info!("Shutting down HOCON language server");
        Ok(())
    }
}

#[tokio::main]
async fn main() {
    // Set up logging
    env_logger::init();
    log::info!("Starting HOCON language server");

    // Create stdin/stdout streams for the server to communicate with the client
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();

    // Create the language server instance
    let (service, socket) = LspService::new(|client| HoconLanguageServer { client });

    // Start the server
    log::info!("Listening on stdin/stdout");
    Server::new(stdin, stdout, socket).serve(service).await;

    log::info!("HOCON language server stopped");
}
