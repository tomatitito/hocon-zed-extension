use zed_extension_api::{self as zed, Result};

struct HoconExtension;

impl zed::Extension for HoconExtension {
    fn new() -> Self {
        HoconExtension
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed_extension_api::LanguageServerId,
        worktree: &zed_extension_api::Worktree,
    ) -> Result<zed::Command> {
        eprintln!(
            "[HOCON Extension] language_server_command called for server: {:?}",
            language_server_id
        );
        eprintln!("[HOCON Extension] worktree received: {:?}", worktree);
        eprintln!(
            "[HOCON Extension] Extension working directory: {:?}",
            std::env::current_dir()
        );

        let hurz = worktree.which("dummy-lsp");

        match hurz {
            Some(path) => {
                eprintln!("[HOCON Extension] Language server found at: {}", path);
                return Ok(zed::Command {
                    command: path,
                    args: vec![],
                    env: vec![],
                });
            }
            None => {
                eprintln!("[HOCON Extension] ERROR: Language server not found: ");
                return Err("Language server not found".to_string());
            }
        }

    }
}

zed::register_extension!(HoconExtension);
