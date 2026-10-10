-- Copy to ~/.config/wezterm/local.lua and edit. Not committed.
return function(config)
    config.ssh_domains = {
        {
            name = "my_server",
            remote_address = "203.0.113.10",
            username = "ubuntu",
            ssh_option = {
                identityfile = "~/.ssh/id_ed25519",
            },
        },
    }
end
