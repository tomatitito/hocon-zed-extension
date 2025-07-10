use zed_extension_api::{self as zed, Result};

struct HoconExtension;


impl zed::Extension for HoconExtension {
    fn new() -> Self {
        eprintln!("[HOCON Extension] Extension initialized!");
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

        let path = "/usr/local/bin/dummy-lsp";
        eprintln!("[HOCON Extension] Language server resolved at: {}", path);

        if std::path::Path::new(&path).exists() {
            eprintln!("[HOCON Extension] Language server binary found.");
            Ok(zed::Command {
                command: path.to_string(),
                args: vec![],
                env: vec![],
            })
        } else {
            eprintln!("[HOCON Extension] Language server binary not found.");
            Err("Language server binary not found".into())
        }

    }
}

zed::register_extension!(HoconExtension);
